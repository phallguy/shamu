module Shamu
  module JsonApi
    class Context

      def initialize( fields: nil )
        @included_resources = {}
        @all_resources = Set.new
        @fields = parse_fields( fields )
      end

      # Add an included resource for a compound response.
      #
      # @param [Object] resource to be serialized.
      # @param [Serializer] the serializer to use to serialize the object. If
      #     not provided a default {Serializer} will be chosen.
      # @return [resource]
      # @yield (builder)
      # @yieldparam [ResourceBuilder] builder to write embedded resource to.
      def include_resource( resource, serializer = nil, &block )
        return if all_resources.include?( resource )

        all_resources << resource
        included_resources[resource] ||= { serializer: serializer, block: block }
      end

      # Collects all the currently included resources and resets the queue.
      def collect_included_resources
        included = included_resources.dup
        @included_resources = {}
        included
      end

      # @return [Boolean] true if there are any pending included resources.
      def included_resources?
        included_resources.any?
      end

      # Check to see if the field should be included in the JSON API output.
      #
      # @param [Symbol] type the resource type in question.
      # @param [Symbol] name of the field on the resouce in question.
      # @return [Boolean] true if the
      def include_field?( type, name )
        return true unless type_fields = fields[ type ]

        type_fields.include?( name )
      end

      private

        attr_reader :all_resources
        attr_reader :included_resources
        attr_reader :fields

        def parse_fields( raw )
          return {} unless raw

          raw.each_with_object( {} ) do |(type, fields), parsed|
            fields = fields.split( "," ) if fields.is_a?( String )

            parsed[ type.to_sym ] = fields.map do |field|
              field = field.strip if field.is_a? String
              field.to_sym
            end
          end
        end
    end
  end
end