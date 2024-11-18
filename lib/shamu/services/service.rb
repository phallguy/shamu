require "scorpion"

module Shamu
  module Services
    # ...
    #
    # ## Well Known Methos
    #
    # - __list( list_scope )__ - lists all of the entities matching the
    #   requested {Entities::ListScope list scope}. Often apply
    #   {Entities::ListScope::Paging} or other filters.
    #
    #     ```
    #     def list( list_scope )
    #       list_scope = UserListScope.coerce! list_scope
    #       entity_list Models::User.by_list_scope( list_scope ) do |record|
    #         scorpion.fetch UserEntity, record: record
    #       end
    #     end
    #     ```
    #
    # - __lookup( *ids )__ - matches a given list of ids to their entities or a
    #   {Entities::NullEntity} for ids that can't be found. The `lookup` method
    #   is typically used to resolve related resources between services -
    #   similar to associations in an ActiveRecord model. Use
    #   {#entity_lookup_list} to transform a list of records or external
    #   resources to a lookup list of entities.
    #
    #     ```
    #     def lookup( *ids )
    #       entity_lookup_list Models::User.where( id: ids ), ids, NullEntity.for( UserEntity ) do |record|
    #         scorpion.fetch UserEntity, record: record
    #       end
    #     end
    #     ```
    #
    # - __find( id )__ - finds a single entity with the given id, raising
    #   {Shamu::NotFoundError} if the resource cannot be found. If the service
    #   also implements `lookup` then this can be implemented by simply aliasing
    #   `find` to {#find_by_lookup}.
    #
    #     ```
    #     def find( id )
    #       find_by_lookup( id )
    #     end
    #     ```
    #
    # - __report( report_scope )__ - Compile a report including metrics, and
    #   master/detail data that make take longer to gather than a standard
    #   `list` request.
    #
    #     ```
    #     def report( report_scope = nil )
    #       report_scope = UserReportScope.coerce! report_scope
    #       scorpion.fetch UserReport, report_scope
    #     end
    #     ```
    class Service
      # Support dependency injection for related services.
      include Scorpion::Object

      def inspect
        result = "<#{self.class.name}:0x#{object_id.to_s(16)}"
        self.class.injected_attributes.map do |attr|
          result << " #{attr.name}=#{send(attr.name).inspect}"
        end
        result << ">"
        result
      end

      def pretty_print(pp)
        pp.object_address_group(self) do
          pretty_print_custom(pp)
          pp.seplist(self.class.injected_attributes, -> { pp.text(",") }) do |attr|
            pp.breakable(" ")
            pp.group(1) do
              pp.text(attr.name.to_s)
              pp.text(":")
              pp.breakable(" ")
              pp.pp(send(attr.name))
            end
          end
        end
      end

      private

        def pretty_print_custom(pp); end

        # Maps a single record to an entity. Requires a `build_entities` method
        # that maps an enumerable set of records to entities.
        #
        # @param [Object] record to map.
        # @return [Entity] the mapped entity.
        def build_entity(record)
          mapped = build_entities([record])
          mapped && mapped.first
        end

        # @!visibility public
        # Takes a raw enumerable list of records and transforms them to a proper
        # {Entities::List}.
        #
        # As simple as the method is, it also serves as a hook for mixins to add
        # additional behavior when processing lists.
        #
        # If a block is not provided, looks for a method `build_entities(
        # records )` that maps a set of records to their corresponding
        # entities.
        #
        # @param [Enumerable] records the raw list of records.
        # @yield (record)
        # @yieldparam [Enumerable<Object>] records the raw values from the `list` to
        #     transform to an {Entities::Entity}.
        # @yieldreturn [Entities::Entity]
        # @return [Entities::List]
        def entity_list(records, &transformer)
          return Entities::List.new([]) unless records

          unless transformer
            unless respond_to?(:build_entities, true)
              raise("Either provide a block or add a private method `def build_entities( records )` to #{self.class.name}.")
            end

            transformer ||= method(:build_entities)
          end

          build_entity_list(build_records_transform(records, &transformer))
        end

        def build_records_transform(records, &transformer)
          LazyTransform.new(records, &transformer)
        end

        def build_entity_list(source)
          Entities::List.new(source)
        end

        # @!visibility public
        # Match a list of records with the ids used to look up those records.
        # Uses a {Entities::NullEntity} if the id doesn't have a matching record.
        #
        # @param [Enumerable] records matching the requested `ids`.
        # @param [Array<Integer>] ids of records found.
        # @param [Class] null_class to use when an id doesn't have a matching
        #     record.
        # @param [Symbol,#call(record)] match the attribute or a Proc used to
        #  extract the id used to compare records.
        # @param [Symbol,#call] coerce a method that can be used to coerce id
        #     values to the same type (eg :to_i). If not set, automatically uses
        #     :to_model_id if match is an 'id' attribute.
        # @yield (see #entity_list)
        # @yieldparam (see #entity_list)
        # @yieldreturn (see #entity_list)
        # @return [Entities::List]
        #
        # @example
        #   def lookup( *ids )
        #     records = Models::Favorite.all.where( id: ids )
        #     entity_lookup_list records, ids, NullEntity.for( FavoriteEntity ) do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }
        #     end
        #   end
        #
        #   def lookup_by_name( *names )
        #     records = Models::Favorite.all.where( :name.in( names ) )
        #
        #     entity_lookup_list records, names, NullEntity.for( FavoriteEntity ), match: :name do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }
        #     end
        #   end
        #
        #   def lookup_by_lowercase( *names )
        #     records = Models::Favorite.all.where( :name.in( names.map( &:downcase ) ) )
        #     matcher = ->( record ) { record.name.downcase }
        #
        #     entity_lookup_list records, names, NullEntity.for( FavoriteEntity ), match: matcher do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }
        #     end
        #   end
        #
        #
        def entity_lookup_list(records, ids, null_class, match: :id, coerce: :not_set, &transformer)
          matcher = entity_lookup_list_matcher(match)
          coerce  = coerce_method(coerce, match)
          ids     = ids.map(&coerce) if coerce

          list = entity_list(records, &transformer)
          matched = ids.map do |id|
            list.find { |e| matcher.call(e) == id } || scorpion.fetch(null_class, id: id)
          end

          build_entity_list(matched)
        end

        ID_MATCHER = ->(record) { record && record.id }

        def entity_lookup_list_matcher(match)
          if !match.is_a?(Symbol) && match.respond_to?(:call)
            match
          elsif match == :id
            ID_MATCHER
          else
            @@matcher_proc_cache ||= Hash.new do |hash, key| # rubocop:disable Style/ClassVars
              hash[key] = ->(record) { record && record.send(key) }
            end

            @@matcher_proc_cache[match]
          end
        end

        def coerce_method(coerce, match)
          return coerce unless coerce == :not_set

          :to_model_id if match.is_a?(Symbol) && match =~ /(^|_)ids?$/
        end

        # @!visibility public
        #
        # For services that expose a standard `lookup` method, find_by_lookup
        # looks up a single entity and raises {Shamu::NotFoundError} if the
        # entity is nil or a {Entities::NullEntity}.
        #
        # A `find` method can then be implemented in terms of the `lookup`
        # method.
        #
        # @param [Integer] id of the entity.
        # @return [Entities::Entity]
        #
        # @example
        #
        #   class Example < Services::Service
        #     def lookup( *ids )
        #       # do something to find the entity
        #     end
        #
        #     def find( id )
        #       find_by_lookup( id )
        #     end
        #   end
        def find_by_lookup(id)
          entity = lookup(id).first
          not_found!(id) unless entity.present?
          entity
        end

        # @exception [Shamu::NotFoundError]
        def not_found!(id = :not_set)
          raise Shamu::NotFoundError.new(id: id)
        end

        # @!visibility public
        #
        # Find an associated entity from a dependent service. Attempts to
        # efficiently handle multiple requests to lookup associations by caching
        # all the associated entities when {#lookup_association} is used
        # repeatedly when building an entity.
        #
        # @param [Object] id of the associated {Entities::Entity} to find.
        # @param [Service] service used to locate the associated resource.
        # @param [IdentityCache] cache to store found associations.
        # @return [Entity] the found entity or a {Entities::NullEntity} if the
        #     association doesn't exist.
        #
        # @example
        #
        #   def build_entities( records )
        #     cache = cache_for( entity: users_service )
        #     owner = lookup_association record.owner_id, users_service, cache do
        #               records.pluck( :owner_id ) if records
        #             end
        #
        #     scorpion.fetch UserEntity, { record: record, owner: owner }
        #   end
        def lookup_association(id, service, cache)
          return unless id

          cache.fetch(id) || begin
            if block_given? && (ids = yield)
              service.lookup(*ids).map do |entity|
                cache.add(entity.id, entity)
              end

              cache.fetch(id)
            else
              association = service.lookup(id).first
              cache.add(association.id, association)
            end
          end
        end

        # @!visibility public
        #
        # Build a proxy object that delays yielding to the block until a method
        # on the association is invoked.
        #
        # @example
        #   user = lazy_association 10, Users::UserEntity do
        #            expensive_lookup_user.find( 10 )
        #          end
        #
        #   user.id   # => 10 expensive lookup not performed
        #   user.name # => "Trump" expensive lookup executed, cached, then
        #             #    method invoked on real object
        #
        # @param [Integer] id of the resource.
        # @param [Class] entity_class of the resource.
        # @return [LazyAssociation<Entity>]
        def lazy_association(id, entity_class, &block)
          return nil if id.nil?

          LazyAssociation.class_for(entity_class).new(id, &block)
        end

        # @!visibility public
        #
        # Get the {Entities::IdentityCache} for the given {Entities::Entity} class.
        # @param [Service#entity_class] dependency_service the dependent
        #   {Service} to cache results from. Must respond to `#entity_class` that
        #   returns the {Entities::Entity} class to cache.
        # @param [Class] entity the type of entity that will be cached. Only
        #     required if the service manages multiple entities.
        # @param [Symbol,#call] key the attribute on the entity, or a custom
        #     block used to obtain the cache key from an entity.
        # @param [Symbol,#call] coerce a method that can be used to coerce key values
        #     to the same type (eg :to_i). If not set, automatically uses :to_i
        #     if key is an 'id' attribute.
        # @return [Entities::IdentityCache]
        def cache_for(dependency_service = nil, key: :id, entity: nil, coerce: :not_set)
          coerce = coerce_method(coerce, key)
          entity ||= dependency_service
          entity = entity.entity_class if entity.respond_to?(:entity_class)

          cache_key        = [entity, key, coerce]
          @entity_caches ||= {}
          @entity_caches[cache_key] ||= scorpion.fetch(Entities::IdentityCache, coerce)
        end

        # @!visibility public
        #
        # Caches the results of looking up the given ids in an {Entities::IdentityCache}
        # and only fetches the records that have not yet been cached.
        #
        # @param (see #cache_for)
        # @param [Array] ids to fetch.
        # @yield (missing_ids)
        # @yieldparam [Array] missing_ids that have not been cached yet.
        # @yieldreturn [Entities::List] the list of entities for the missing ids.
        #
        # @example
        #
        #   def lookup( *ids )
        #     cached_lookup( ids ) do |missing_ids|
        #       entity_lookup_list( Models::User.where( id: missing_ids ), missing_ids, UserEntity::Missing )
        #     end
        #   end
        def cached_lookup(ids, match: :id, coerce: :not_set, entity: nil, &lookup)
          coerce      = coerce_method(coerce, match)
          ids         = ids.map(&coerce) if coerce
          cache       = cache_for(key: match, coerce: coerce, entity: entity)
          missing_ids = cache.uncached_keys(ids)

          cache_entities(cache, match, missing_ids, &lookup) if missing_ids.any?

          entities = ids.map { |id| cache.fetch(id) || raise(Shamu::NotFoundError) }
          Entities::List.new(entities)
        end

        def cache_entities(cache, match, missing_ids)
          matcher = entity_lookup_list_matcher(match)
          if list = yield(missing_ids)
            list.each do |e|
              if e.empty?
                # For NullEntitty, the id for a custom field or matcher will
                # still always be assigned to the entity id.
                cache.add(e.id, e)
              else
                cache.add(matcher.call(e), e)
              end
            end
          end
        end

        # @!visbility public
        #
        # After a mutation method call to make sure the cache for the entity
        # is updated to reflect the new entity state.
        #
        # @param [Entity] entity in the new modified state.
        def recache_entity(entity, match: :id)
          matcher = entity_lookup_list_matcher(match)
          cache = cache_for(key: match)

          cache.add(matcher.call(entity), entity)
        end
    end
  end
end
