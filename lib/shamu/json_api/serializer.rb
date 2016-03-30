module Shamu
  module JsonApi

    # Serialize an object to a JSON API stream.
    class Serializer

      # @param [Object] resource to be serialized.
      def initialize( resource )
        @resource = resource
      end

      # Serialize the {#resource} to the builder.
      # @param [ResourceBuilder] builder to write to.
      # @return [void]
      def serialize( builder )
      end

      private

        attr_reader :resource

      class << self

        # Find a {Serializer} that knows how to serialize the given resource.
        # @param [Object] resource to serialize.
        # @return [Serializer]
        def find( resource )
        end
      end

    end
  end
end