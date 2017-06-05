require "shamu/services"

module Shamu
  module Entities

    # Implements an {EntityLookupService} that works with {OpaqueId} encoded
    # values to obfuscate the contents and type of record identified by the id.
    # Useful for implementing guidelines for globally unique IDs in a GraphQL
    # system.
    #
    # ```
    # Scorpion.prepare do
    #   capture Shamu::Entities::EntityLookupService do |scorpion|
    #     scorpion.new( Shamu::Entities::OpaqueEntityLookupService, { "User" => Users::ExternalUsersService }, {} )
    #   end
    # end
    # ```
    class OpaqueEntityLookupService < EntityLookupService

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [EntityLookupService] the underlying lookup service to use.
      attr_dependency :lookup_service, EntityLookupService do |scorpion|
        scorpion.new( EntityLookupService, { entity_map: entity_map }, {} )
      end


      #
      # @!endgroup Dependencies

      # (see {EntityLookupService#ids)
      def ids( entities )
        super.map do |id|
          OpaqueId.opaque_id( id )
        end
      end

      # (see {EntityLookupService#record_ids)
      def record_ids( ids )
        super( ids_to_entity_paths( ids ) )
      end

      # (see {EntityLookupService#lookup)
      def lookup( *ids )
        super( *ids_to_entity_paths( ids ) )
      end

      private

        def ids_to_entity_paths( ids )
          Array.wrap( ids ).map { |id| OpaqueId.to_entity_path( id ) }
        end

    end
  end
end
