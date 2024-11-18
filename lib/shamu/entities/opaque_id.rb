module Shamu
  module Entities
    # A collection of helper methods for building and reconstructing opaque
    # entity ids. These ids can be used to uniquely reference a resource within
    # the system without knowing the type or service.
    #
    # See {EntityLookupService} for lookup up resources by opaque ID.
    module OpaqueId
      module_function

      PATTERN = %r{\A[a-zA-Z0-9+/]+={0,3}\z}
      NUMERICAL = /\A[0-9]+\z/

      # @return [String] an opaque value that uniquely identifies the
      # entity.
      def opaque_id(entity)
        path = if entity.is_a?(String)
                 entity
               else
                 Entity.compose_entity_path([entity])
               end

        Base64.strict_encode64(path).chomp("=").to_s
      end

      # @return [String,Integer] the encoded raw record id.
      def to_model_id(opaque_id)
        if path = to_entity_path(opaque_id)
          path = EntityPath.decompose_entity_path(path)
          path.first.last.to_model_id
        else
          opaque_id.to_model_id
        end
      end

      # @return [Array<[String, String]>] decodes the id to it's {EntityPath}.
      def to_entity_path(opaque_id)
        return nil unless opaque_id && NUMERICAL !~ opaque_id

        id = opaque_id
        id += "=" * (4 - (id.length % 4)) if id.length % 4 > 0

        Base64.strict_decode64(id)
      end

      # @param [String] value candidate value
      # @return [Boolean] true if the given value is an opaque id.
      def opaque_id?(value)
        return false unless value

        PATTERN =~ value && NUMERICAL !~ value
      end
    end
  end
end
