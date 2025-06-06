module Shamu
  module Services
    # Adds standard CRUD builders to an {ActiveRecordService} to reduce
    # boilerplate for common methods.
    #
    # @example
    #
    #   class UsersService < Shamu::Services::Service
    #     include Shamu::Services::ActievRecordCrud
    #
    #     # Define the resource that the service will manage
    #     resource UserEntity, Models::User
    #
    #     # Define finder methods #find, #list and #lookup using the given
    #     # default scope.
    #     define_finders Models::User.active
    #
    #     # Define change methods
    #     define_create
    #     define_update
    #
    #     # Common update/change behavior for #create and #update
    #     define_change do |request, model|
    #       model.last_updated_at = Time.now
    #     end
    #
    #     # Standard destroy method
    #     define_destroy
    #
    #     # Build the entity class from the given record.
    #     define_build_entities do |records|
    #       records.map do |record|
    #         parent = lookup_association( record.parent_id, self ) do
    #                    records.pluck( :parent_id )
    #                  end
    #
    #         scorpion.fetch UserEntity, { parent: parent }
    #       end
    #     end
    #   end
    module ActiveRecordCrud
      extend ActiveSupport::Concern

      # Known DSL methods defined by {ActiveRecordCrud}.
      DSL_METHODS = %i[create update change destroy find list lookup finders crud].freeze

      included do |base|
        base.include(Shamu::Services::RequestSupport)
        base.include(Shamu::Services::ActiveRecord)
      end

      private

        def model_class
          self.class.model_class
        end

        def entity_class
          self.class.entity_class
        end

        def transform_ids(ids)
          if entity_class.respond_to?(:unhash_id)
            ids.map { |id| entity_class.unhash_id(id) }
          else
            ids
          end
        end

        # @!visibility public
        #
        # Hook to allow a security module to authorize actions taken by the
        # standard CRUD methods. If authorization is not granted, then an
        # exception should be raised. Default behavior is a no-op.
        #
        # @param [Symbol] method on the service that was invoked.
        # @param [Entities::Entity, Class, Symbol] resource the entity, class or
        #     arbitrary symbol describing the resource that the service method
        #     applies to.
        # @param [Object] additional_context that the security module might
        #     consider when authorizing the transaction.
        # @return [resource] the resource given to authorize.
        def authorize!(_method, resource, _additional_context = nil)
          resource
        end

        # @!visibility public
        #
        # Hook to allow a security module to pre-filter ActiveRecord queries
        # for the standard crud methods. Default behavior is a no-op.
        #
        # @param [Symbol] method on the service that was invoked.
        # @param [ActiveRecord::Relation] relation to filter
        # @param [Object] additional_context that the security module might
        #     consider when authorizing the transaction.
        #
        # @return [relation] the filtered relation.
        def authorize_relation(_method, relation, _additional_context = nil)
          relation
        end

        def not_found!(id = :not_set)
          raise Shamu::NotFoundError.new(id: id, resource: entity_class)
        end

        # Hook to all service to redact attributes from the entities that
        # should not be exposed based on the current security principal.
        #
        # @param [Enumerable<Shamu::Entities::Entity>] entities to redact
        # @return [Enumerable<Shamu::Entities::Entity>] the redacted
        # entities.
        def redact_entities(entities)
          entities
        end

        def redact_entity(entity)
          redact_entities([entity]).first
        end

        # Hook to post-process entity list before returning it to the caller.
        # @param [Enumerable<Shamu::Entities::Entity>] entities to return
        # @return [Enumerable<Shamu::Entities::Entity>] the processed
        # entities.
        def return_entities(entities)
          redact_entities(entities)
        end

        def handle_active_record_error(error, request)
          case error
          when ::ActiveRecord::RecordNotUnique
            request.reject(:base, :unique_constraint)
          else
            raise error
          end
        end

        class_methods do
          # Declare the entity and resource classes used by the service.
          #
          # Creates instance and class level methods `entity_class` and
          # `model_class`.
          #
          # See {.build_entities} for build_entities block details.
          #
          # @param [Class] entity_class the {Entities::Entity} class that will be
          #   returned by finders and mutator methods.
          # @param [Class] model_class the {ActiveRecord::Base} model
          # @param [Array<Symbol>] methods the {DSL_METHODS DSL methods} to
          #     include (eg :create, :update, :find, etc.)
          # @yield ( records )
          # @yieldparam [ActiveRecord::Relation] records to be mapped to an
          #   entity.
          # @yieldreturn [Entities::Entity] the entity projection for the given
          #     record.
          # @return [void]
          def resource(entity_class, model_class, methods: nil, &block)
            private(define_method(:entity_class)   { entity_class })
            define_singleton_method(:entity_class) { entity_class }

            private(define_method(:model_class)    { model_class })
            define_singleton_method(:model_class)  { model_class }

            (Array(methods) & DSL_METHODS).each do |method|
              send(:"define_#{method}")
            end

            define_build_entities(&block)
          end

          # @return [Class] the {Entities::Entity} class that the service will
          #     return from it's methods.
          def entity_class
            resource_not_configured
          end

          # @return [Class] the {ActiveRecord::Base} class used to store the data
          #     managed by the service.
          def model_class
            resource_not_configured
          end

          # Define all basic CRUD methods without any customization.
          def define_crud
            define_create
            define_update
            define_destroy
            define_finders
          end

          # Define a `#create` method on the service that takes a single {Request}
          # parameter.
          #
          # @yield ( request, record, *args )
          # @yieldparam [Services::Request] request object.
          # @yieldparam [ActiveRecord::Base] record.
          # @yieldparam [Array] args any additional arguments injected by an
          # overridden {#with_request} method.
          # @return [void]
          def define_create(method = :create, &block)
            define_method(method) do |params = nil|
              with_request(params, request_class(method)) do |request, *args|
                record = request.apply_to(model_class.new)

                if block_given?
                  result = instance_exec(record, request, *args, &block)
                  next result if result.is_a?(Services::Result)
                  next unless request.valid?
                end

                authorize!(method, build_entity(record), request)

                next record unless record.save

                redact_entity(build_entity(record))
              rescue ::ActiveRecord::ActiveRecordError => e
                handle_active_record_error(e, request)
              end
            end
          end

          # Define an change `method` on the service that takes the id of the
          # resource to modify and a corresponding {Request} parameter.
          #
          # @yield ( request, record, *args )
          # @yieldparam [Services::Request] request object.
          # @yieldparam [ActiveRecord::Base] record.
          # @yieldparam [Array] args any additional arguments injected by an
          # overridden {#with_request} method.
          # @return [Result] the result of the request.
          # @return [void]
          def define_change(method, default_scope = model_class, &block)
            define_method(method) do |id, params = nil|
              klass = request_class(method)

              id, params = extract_params(id, params)

              with_partial_request(params, klass) do |request, *args|
                record = default_scope.find(id.to_model_id || request.id)
                entity = build_entity(record)

                backfill_attributes = entity.to_attributes(only: request.unassigned_attributes)
                request.assign_attributes(backfill_attributes)
                next unless request.valid?

                if defined? security_context
                  security_context.provide(:entity) { entity.id }
                end

                authorize!(method, entity, request)

                request.apply_to(record)
                if block_given?
                  result = instance_exec(record, request, *args, &block)
                  next result if result.is_a?(Services::Result)
                  next unless request.valid?
                end

                next record unless record.save

                redact_entity(build_entity(record))
              rescue ::ActiveRecord::ActiveRecordError => e
                handle_active_record_error(e, request)
              end
            end
          end

          # Defines an #update method. See {#define_change} for details.
          def define_update(default_scope = model_class, &block)
            define_change(:update, default_scope, &block)
          end

          # Define an command `method` on the service that takes a request that
          # does not identify a record by id and performs some action.
          #
          # @param [Symbol] method name to give the new method.
          # @param [#call] record_lookup a callable that receives the request
          # object and returns the record to be modified.
          # @yield ( request, *args )
          # @yieldparam [Services::Request] request object.
          # @yieldparam [Array] args any additional arguments injected by an
          # overridden {#with_request} method.
          # @return [Result] the result of the request.
          # @return [void]
          def define_command(method, record_lookup, &block)
            lookup_name = :"_lookup_#{method}_record"
            define_method(lookup_name, &record_lookup)
            define_method(method) do |params|
              klass = request_class(method)

              with_request(params, klass) do |request, *args|
                if record = send(lookup_name, request)
                  entity = build_entity(record)

                  if defined? security_context
                    security_context.provide(:entity) { entity.id }
                  end

                  authorize!(method, entity, request)

                  request.apply_to(record)
                else
                  authorize!(method, entity_class, request)
                end

                if block_given?
                  result = instance_exec(record, request, *args, &block)
                  next result if result.is_a?(Services::Result)
                  next unless request.valid?
                end

                next record unless record.save

                redact_entity(build_entity(record))
              rescue ::ActiveRecord::ActiveRecordError => e
                handle_active_record_error(e, request)
              end
            end
          end

          # Define a `destroy( id )` method that takes an {Entities::Entity} {Entities::Entity#id}
          # and destroys the resource.
          #
          # @yield ( request, record, *args )
          # @yieldparam [Services::Request] request object.
          # @yieldparam [ActiveRecord::Base] record.
          # @yieldparam [Array] args any additional arguments injected by an
          # overridden {#with_request} method.
          # @param [ActiveRecord::Relation] default_scope to use when finding
          #     records.
          # @return [void]
          def define_destroy(method = :destroy, default_scope = model_class, &block)
            define_method(method) do |params|
              klass = request_class(method)

              params = { id: params } if params.respond_to?(:to_model_id)

              with_request(params, klass) do |request, *args|
                record = default_scope.find(request.id)
                entity = build_entity(record)

                if defined? security_context
                  security_context.provide(:entity) { entity.id }
                end

                authorize!(method, entity, request)

                if block_given?
                  instance_exec(record, request, *args, &block)
                  next unless request.valid?
                end

                next record unless record.destroy

                entity
              rescue ::ActiveRecord::ActiveRecordError => e
                handle_active_record_error(e, request)
              end
            end
          end

          # Define the standard finder methods {.find}, {.lookup} and {.list}.
          #
          # @param [ActiveRecord::Relation] default_scope to use when finding
          #     records.
          # @return [void]
          def define_finders(default_scope: model_class.all, list_scope: nil, only: nil, except: nil)
            methods = Array(only || %i[find lookup list])
            methods -= Array(except) if except

            methods.each do |method|
              if method == :list
                send(:"define_#{method}", default_scope: default_scope, list_scope: list_scope)
              else
                send(:"define_#{method}", default_scope: default_scope)
              end
            end
          end

          # Define a `find( id )` method on the service that returns the entity
          # with the given id if found or raises a {Shamu::NotFoundError} if the
          # entity does not exist.
          #
          # @param [ActiveRecord::Relation] default_scope to use when finding
          #     records.
          # @yield (id)
          # @yieldreturn (ActiveRecord::Base) the found record.
          # @return [void]
          def define_find(default_scope: model_class.all, &block)
            if block_given?
              define_method(:_find_block, &block)
              define_method(:find) do |id|
                wrap_not_found do
                  record = _find_block(id)
                  entity = build_entity(record)

                  if defined? security_context
                    security_context.provide(:entity) { entity.id }
                  end

                  redact_entity(authorize!(:read, entity))
                end
              end
            else
              define_method(:find) do |id|
                authorize!(:read, find_by_lookup(id))
              end
            end
          end

          # Define a `lookup( *ids )` method that takes a list of entity ids to
          # find. Calls {#build_entities} to map all found records to entities,
          # or constructs a {Entities::NullEntity} for ids that were not found.
          #
          # @param [ActiveRecord::Relation] default_scope to use when finding
          #     records.
          # @yield (uncached_ids)
          # @yieldparam [Array<Object>] ids that need to be fetched from the
          #     underlying resource.
          # @yieldreturn [ActiveRecord::Relation] records for ids found in the
          #     underlying resource.
          # @return [void]
          def define_lookup(default_scope: model_class.all, &block)
            if block_given?
              define_method(:_lookup_block, &block)
            else
              define_method(:_lookup_block) do |ids|
                default_scope.where(id: ids)
              end
            end

            define_method(:lookup) do |*ids|
              transformed_ids = transform_ids(ids)

              redact_entities(
                cached_lookup(transformed_ids) do |uncached_ids|
                  records = _lookup_block(uncached_ids)
                  records = authorize_relation(:read, records)
                  entity_lookup_list(records, uncached_ids, entity_class.null_entity)
                end
              )
            end
          end

          # Define a `list( params = nil )` method that takes a
          # {Entities::ListScope} and returns all the entities selected by that
          # scope.
          #
          # @param [ActiveRecord::Relation] default_scope to use when finding
          #     records.
          # @yield (scope)
          # @yieldparam [ListScope] scope to apply.
          # @yieldreturn [ActiveRecord::Relation] records matching the given scope.
          # @return [void]
          def define_list(default_scope: model_class.all, list_scope: nil, &block)
            define_method(:list) do |params = nil|
              list_scope_class = list_scope || Entities::ListScope.for(entity_class)
              scope = list_scope_class.coerce(params)
              authorize!(:list, entity_class, scope)

              records =
                if block_given?
                  instance_exec(default_scope, scope, &block)
                else
                  scope_relation(default_scope, scope)
                end

              records = authorize_relation(:list, records, scope)

              redact_entities(entity_list(records))
            end

            define_find_by
          end

          def define_find_by
            define_method(:find_by) do |params = nil|
              entity = list(params).first
              not_found! if entity.blank?
              entity
            end
          end

          # Define a private `build_entities( records )` method that
          # constructs an {Entities::Entity} for each of the given `records`.
          #
          # If no block is given, creates a simple builder that simply constructs
          # an instance of the {.entity_class} passing `record: record` to the
          # initializer.
          #
          # See {Service#lookup_association} for details on association caching.
          #
          # @yield ( records )
          # @yieldparam [ActiveRecord::Relation] records to be mapped to
          #   entities.
          # @yieldreturn [Array<Entities::Entity>] the projected entities.
          # @return [void]
          def define_build_entities(&block)
            if block_given?
              define_method(:build_entities, &block)
            else
              define_method(:build_entities) do |records|
                records.map do |record|
                  scorpion.fetch(entity_class, record: record)
                end
              end
            end

            private(:build_entities)
          end

          private

            def resource_not_configured
              raise IncompleteSetupError, "Resource has not been defined. Add `resource #{inferred_namespace}#{inferred_resource_name}Entity, #{inferred_namespace}Models::#{inferred_resource_name}` to #{name}."
            end

            def inferred_resource_name
              inferred = name || "Resource"
              inferred.split("::").last.sub("Service", "").singularize
            end

            def inferred_namespace
              parts = (name || "Resource").split("::")
              parts.pop
              return "" if parts.empty?

              parts.join("::") << "::"
            end
        end
    end
  end
end
