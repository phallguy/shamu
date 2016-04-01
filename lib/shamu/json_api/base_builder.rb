module Shamu
  module JsonApi

    # Used by a {Serilaizer} to write fields and relationships
    class BaseBuilder

      # @param [Context] context the current serialization context.
      def initialize( context )
        @context = context
        @output = {}
      end

      # @overload identifier( type, id )
      #   @param [String] type of the resource.
      #   @param [Object] id of the resource.
      # @overload identifier( resource )
      #   @param [#json_api_type,#id] resource an object that responds to `json_api_type` and `id`
      #
      # Write a resource linkage info.
      #
      # @return [void]
      def identifier( type, id = nil )
        type, id = type.json_api_type, type.id if type.respond_to? :json_api_type

        output[:type] = type.to_s
        output[:id]   = id.to_s
      end

      # Write a link  to another resource.
      #
      # @param [String,Symbol] name of the link.
      # @param [String] url
      # @param [Hash] meta optional additional meta information.
      # @return [void]
      def link( name, url, meta: nil )
        links = ( output[:links] ||= {} )

        if meta # rubocop:disable Style/ConditionalAssignment
          links[ name.to_sym ] = { href: url, meta: meta }
        else
          links[ name.to_sym ] = url
        end
      end

      # Add a meta field.
      # @param [String,Symbol] name of the meta field.
      # @param [Object] vlaue that can be converted to a JSON primitive type.
      # @return [void]
      def meta( name, value )
        meta = ( output[:meta] ||= {} )
        meta[ name.to_sym ] = value
      end

      # @return [Hash] the results output as JSON safe hash.
      def compile
        fail JsonApi::IncompleteResourceError unless output[:type]
        output
      end

      private

        attr_reader :context
        attr_reader :output

    end
  end
end