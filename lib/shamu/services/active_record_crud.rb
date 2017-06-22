module Shamu
  module Services

    # Adds standard CRUD builders to an {ActiveRecordService} to reduce
    # boilerplate for common methods.
    #
    # @example
    #
    #   class UsersService < Shamu::Services::Service
    #     include Shamu::Services::Crud
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
    #         scorpion.fetch UserEntity, { parent: parent }, {}
    #       end
    #     end
    #   end
    module ActiveRecordCrud
      extend ActiveSupport::Concern

      # Known DSL methods defined by {ActiveRecordCrud}.
      DSL_METHODS = %i[ create update change destroy find list lookup finders crud ].freeze

      included do |base|
        base.include Shamu::Services::RequestSupport
        base.include Shamu::Services::ActiveRecord
      end

      private

        def model_class
          self.class.model_class
        end

        def entity_class
          self.class.model_class
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
        def authorize!( method, resource, additional_context = nil )
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
        def authorize_relation( method, relation, additional_context = nil )
          relation
        end

        def not_found!( id = :not_set )
          raise Shamu::NotFoundError, id: id, resource: entity_class
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
        def resource( entity_class, model_class, methods: nil, &block )
          private define_method( :entity_class )   { entity_class }
          define_singleton_method( :entity_class ) { entity_class }

          private define_method( :model_class )    { model_class }
          define_singleton_method( :model_class )  { model_class }

          ( Array( methods ) & DSL_METHODS ).each do |method|
            send :"define_#{ method }"
          end

          define_build_entities( &block )
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
        def define_create( &block )
          define_method :create do |params = nil|
            with_request params, request_class( :create ) do |request, *args|
              record = request.apply_to( model_class.new )

              if block_given?
                result = instance_exec record, request, *args, &block
                next result if result.is_a?( Services::Result )
              end

              authorize! :create, build_entity( record ), request

              next record unless record.save
              build_entity record
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
        def define_change( method, default_scope = model_class, &block ) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/LineLength
          define_method method do |id, params = nil|
            klass = request_class( method )

            params, id = id, id[ :id ] if !params && !id.respond_to?( :to_model_id )
            params[ :id ] ||= id       if params

            with_partial_request params, klass do |request, *args|
              record = default_scope.find( id.to_model_id || request.id )
              entity = build_entity( record )

              backfill_attributes = entity.to_attributes( only: request.unassigned_attributes )
              request.assign_attributes backfill_attributes
              next unless request.valid?

              authorize! method, entity, request

              request.apply_to( record )
              if block_given?
                result = instance_exec record, request, *args, &block
                next result if result.is_a?( Services::Result )
              end

              next record unless record.save
              build_entity record
            end
          end
        end

        # Defines an #update method. See {#define_change} for details.
        def define_update( default_scope = model_class, &block )
          define_change :update, default_scope, &block
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
        def define_destroy( default_scope = model_class, &block )
          define_method :destroy do |params|
            klass = request_class( :destroy )

            params = { id: params } if params.respond_to?( :to_model_id )

            with_request params, klass do |request, *args|
              record = default_scope.find( request.id )
              authorize! :destroy, build_entity( record ), request

              instance_exec record, request, *args, &block if block_given?
              next record unless record.destroy
            end
          end
        end

        # Define the standard finder methods {.find}, {.lookup} and {.list}.
        #
        # @param [ActiveRecord::Relation] default_scope to use when finding
        #     records.
        # @return [void]
        def define_finders( default_scope = model_class.all, only: nil, except: nil )
          methods = Array( only || [ :find, :lookup, :list ] )
          methods -= Array( except ) if except

          methods.each do |method|
            send :"define_#{ method }", default_scope
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
        def define_find( default_scope = model_class.all, &block )
          if block_given?
            define_method :find do |id|
              wrap_not_found do
                record = yield( id )
                authorize! :read, build_entity( record )
              end
            end
          else
            define_method :find do |id|
              authorize! :read, find_by_lookup( id )
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
        def define_lookup( default_scope = model_class.all, &block )
          define_method :lookup do |*ids|
            cached_lookup( ids ) do |uncached_ids|
              records = block_given? ? yield( uncached_ids ) : default_scope.where( id: uncached_ids )
              records = authorize_relation :read, records
              entity_lookup_list records, uncached_ids, entity_class.null_entity
            end
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
        def define_list( default_scope = model_class.all, &block )
          define_method :list do |params = nil|
            list_scope = Entities::ListScope.for( entity_class ).coerce( params )
            authorize! :list, entity_class, list_scope

            records    = block_given? ? yield( scope ) : scope_relation( default_scope, list_scope )
            records    = authorize_relation( :read, records, list_scope )

            entity_list records
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
        def define_build_entities( &block )
          if block_given?
            define_method :build_entities, &block
          else
            define_method :build_entities do |records|
              records.map do |record|
                entity = scorpion.fetch( entity_class, { record: record }, {} )
                authorize! :read, entity
              end
            end
          end

          private :build_entities
        end

        private

          def resource_not_configured
            raise IncompleteSetupError, "Resource has not been defined. Add `resource #{ inferred_namespace }#{ inferred_resource_name }Entity, #{ inferred_namespace }Models::#{ inferred_resource_name }` to #{ name }." # rubocop:disable Metrics/LineLength
          end

          def inferred_resource_name
            inferred = name || "Resource"
            inferred.split( "::" ).last.sub( /Service/, "" ).singularize
          end

          def inferred_namespace
            parts = ( name || "Resource" ).split( "::" )
            parts.pop
            return "" if parts.empty?
            parts.join( "::" ) << "::"
          end

      end

    end
  end
end
