require "shamu/services"

module Shamu
  module Entities

    # Looks up entities from compiled {EntityPath} strings allowing references
    # to be stored as opaque values in an external service and later looked up
    # without knowing which services are required to look up the entities.
    #
    # Useful for implementing a `node` field in a Relay GraphQL endpoint or
    # resolving entities in an {Auditing::AuditingService audit log}.
    #
    # {#lookup} maps entity types to the service class used to look up entities
    # of that type. The services must implement the well known `#lookup` method
    # that takes an array of ids as an argument.
    #
    # If there is no entry mapping in the `entity_map` provided to the
    # constructor then EntityLookupService will attempt to locate a service
    # named {Entities}Service in the same namespace as the entity type.
    #
    # The EntityLookupService should be configured as a per-request singleton
    # in Scorpion with all custom entity mappings set.
    #
    # ```
    # Scorpion.prepare do
    #   capture Shamu::Entities::EntityLookupService do |scorpion|
    #     scorpion.new( Shamu::Entities::EntityLookupService, { "User" => Users::ExternalUsersService }, {} )
    #   end
    # end
    # ```
    class EntityLookupService < Shamu::Services::Service

      def initialize( entity_map = nil )
        entity_map ||= {}
        @entity_map_cache = Hash.new do |hash, entity_type|
          hash[ entity_type ] = entity_map[ entity_type ] \
                                || entity_map[ entity_type.to_s ] \
                                || find_implicit_service_class( entity_type.to_s )
        end
        super()
      end

      # Gets the class of the service used to look up entities of the given
      # type. Use a scorpion to get an instance of the service class.
      #
      # @return [Shamu::Services::Service] a service that implements `#lookup`.
      def service_class_for( entity_type )
        entity_map_cache[ entity_type.to_sym ]
      end

      # Map the given entities to their {EntityPath} that can later be used to
      # {#lookup} the given entity.
      def ids( entities )
        Array.wrap( entities ).map do |entity|
          EntityPath.compose_entity_path( [ entity ] )
        end
      end

      # Map the encoded ids back to their raw record IDs discarding any type
      # information.
      #
      # @param [Array<String>] ids an array of ids encoded with {#ids}.
      def record_ids( ids )
        Array.wrap( ids ).map do |id|
          EntityPath.decompose_entity_path( id ).first.last.to_model_id
        end
      end

      # Look up all the entities from their composed {EntityPath}.
      #
      # @param [Array<String>] ids an array of {EntityPath} strings.
      # @return [EntityList<Entity>] the entities in the same order as the
      # given ids.
      def lookup( *ids ) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        types = {}

        # Decompose entity paths and group by entity type
        ids.each do |composed|
          path = EntityPath.decompose_entity_path( composed )
          fail "Only root entities can be restored" unless path.size == 1
          type, id = path.first

          types[ type ] ||= { paths: [], ids: [] }

          types[ type ][ :paths ] << composed
          types[ type ][ :ids ]   << id
        end

        # Short-circuit if we only have one entity type
        if types.size == 1
          service_class = service_class_for( types.first.first )
          service = scorpion.fetch service_class

          return service.lookup( *types.first.last[ :ids ] )
        end

        # Lookup all entities in batches
        hydrated = types.map do |type, map|
          service_class = service_class_for( type )
          service = scorpion.fetch service_class

          entities = service.lookup( *map[ :ids ] )

          Hash[ map[ :paths ].zip( entities ) ]
        end

        # Map found entities back to their original input order
        mapped = ids.map do |id|
          found = nil
          hydrated.each do |map|
            break if found = map[ id ]
          end

          found
        end

        Entities::List.new mapped
      end

      private

        attr_reader :entity_map_cache

        def find_implicit_service_class( entity_type )
          namespace = entity_type.deconstantize
          type      = entity_type.demodulize

          service_name = [
                           namespace,
                           "#{ type.pluralize }Service"
                         ].join( "::" )

          service_name.constantize
        end
    end
  end
end
