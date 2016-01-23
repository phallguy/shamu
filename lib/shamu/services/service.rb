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
    #       scorpion.fetch UserReport, report_scope, {}
    #     end
    #     ```
    class Service

      # Support dependency injection for related services.
      include Scorpion::Object

      private

        # @!visibility public
        # Takes a raw enumerable list of records and transforms them to a proper
        # {Entities::List}.
        #
        # As simple as the method is, it also serves as a hook for mixins to add
        # additional behavior when processing lists.
        #
        # If a block is not provided, looks for a method `build_entity(record,
        # records=nil)` where `record` is the individual record to be
        # transformed and `records` is the original collection or database query
        # being transformed.
        #
        # @param [Enumerable] records the raw list of records.
        # @yield (record)
        # @yieldparam [Object] record the raw value from the `list` to to
        #     transform to an {Entities::Entity}.
        # @yieldresult [Entities::Entity]
        # @return [Entities::List]
        def entity_list( records, &transformer )
          return Entities::List.new unless records
          unless transformer
            fail "Either provide a block or add a private method `def build_entity( record, records = nil )` to #{ self.class.name }." unless respond_to?( :build_entity ) # rubocop:disable Metrics/LineLength
            transformer ||= ->( record ) { build_entity( record, records ) }
          end

          Entities::List.new LazyTransform.new( records, &transformer )
        end

        # @!visibility public
        # Match a list of records with the ids used to look up those records.
        # Uses a {NullEntity} if the id doesn't have a matching record.
        #
        # @param [Enumerable] records matching the requested `ids`.
        # @param [Array<Integer>] ids of records found.
        # @param [Class] null_class to use when an id doesn't have a matching
        #     record.
        # @param [Symbol,#call(record)] match the attribute or a Proc used to
        #  extract the id used to compare records.
        # @yield (see #entity_list)
        # @yieldparam (see #entity_list)
        # @yieldresult (see #entity_list)
        # @return [Entities::List]
        #
        # @example
        #   def lookup( *ids )
        #     records = Models::Favorite.all.where( id: ids )
        #     entity_lookup_list records, ids, NullEntity.for( FavoriteEntity ) do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }, {}
        #     end
        #   end
        #
        #   def lookup_by_name( *names )
        #     records = Models::Favorite.all.where( :name.in( names ) )
        #
        #     entity_lookup_list records, names, NullEntity.for( FavoriteEntity ), match: :name do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }, {}
        #     end
        #   end
        #
        #   def lookup_by_lowercase( *names )
        #     records = Models::Favorite.all.where( :name.in( names.map( &:downcase ) ) )
        #     matcher = ->( record ) { record.name.downcase }
        #
        #     entity_lookup_list records, names, NullEntity.for( FavoriteEntity ), match: matcher do |record|
        #       scorpion.fetch FavoriteEntity, { record: record }, {}
        #     end
        #   end
        #
        #
        def entity_lookup_list( records, ids, null_class, match: :id, &transformer )
          matcher = entity_lookup_list_matcher( match )
          ids     = ids.map( &:to_i ) if match.is_a?( Symbol ) && match =~ /(^|_)id$/

          list = entity_list records, &transformer
          matched = ids.map do |id|
            list.find { |e| matcher.call( e ) == id } || scorpion.fetch( null_class, { id: id }, {} )
          end

          Entities::List.new( matched )
        end

          def entity_lookup_list_matcher( match )
            if !match.is_a?( Symbol ) && match.respond_to?( :call )
              match
            elsif match == :id
              ->( record ) { record && record.id }
            else
              ->( record ) { record && record.send( match ) }
            end
          end

        # @!visibility public
        #
        # For services that expose a standard `lookup` method, find_by_lookup
        # looks up a single entity and raises {Shamu::NotFoundError} if the
        # entity is nil or a {NullEntity}.
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
        def find_by_lookup( id )
          entity = lookup( id ).first
          raise Shamu::NotFoundError unless entity.present?
          entity
        end

        # @!visibility public
        #
        # @overload result( *validation_sources, request: nil, entity: nil )
        # @param (see Result#initialize)
        # @return [Result]
        def result( *args )
          Result.new( *args )
        end

        # @!visibility public
        #
        # Return an error {#result} from a service request.
        # @overload error( attribute, message )
        # @param (see ErrorResult#initialize)
        # @return [ErrorResult]
        def error( *args )
          Result.new.tap do |r|
            r.errors.add( *args )
          end
        end

        # @param [String,Integer,#to_model_id] value
        # @return [Boolean] true if the value looks like an ID.
        def model_id?( value )
          case Array( value ).first
          when Integer then true
          when String  then ToModelIdExtension::Strings::NUMERIC_PATTERN =~ value
          end
        end
    end
  end
end