module Shamu
  module Entities

    # A collection of helper methods for building and reconstructing opaque
    # entity ids. These ids can be used to uniquely reference a resource within
    # the system without knowing the type or service.
    #
    # See {EntityLookupService} for lookup up resources by opaque ID.
    module OpaqueId
      module_function

      PREFIX  = "::".freeze
      PATTERN = %r{\A#{ PREFIX }[a-zA-Z0-9+/]+={0,3}\z}

      # @return [String] an opaque value that uniquely identifies the
      # entity.
      def opaque_id( entity )
        path = if entity.is_a?( String )
                 entity
               else
                 Entity.compose_entity_path( [ entity ] )
               end

        "#{ PREFIX }#{ Base64.strict_encode64( path ) }"
      end

      # @return [String,Integer] the encoded raw record id.
      def to_model_id( opaque_id )
        if path = to_entity_path( opaque_id )
          path = EntityPath.decompose_entity_path( path )
          path.first.last.to_model_id
        else
          opaque_id.to_model_id
        end
      end

      # @return [Array<[String, String]>] decodes the id to it's {EntityPath}.
      def to_entity_path( opaque_id )
        return nil unless opaque_id && opaque_id.start_with?( PREFIX )

        id = opaque_id[ PREFIX.length..-1 ]
        id = Base64.strict_decode64( id )
        id
      end

      # @param [String] value candidate value
      # @return [Boolean] true if the given value is an opaque id.
      def opaque_id?( value )
        return unless value
        PATTERN =~ value
      end
    end
  end
end
