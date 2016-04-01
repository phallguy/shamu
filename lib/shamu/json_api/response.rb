module Shamu
  module JsonApi

    # Build a JSON API response from one or more resources.
    class Response < BaseBuilder

      # Output a single resource as the response data.
      # @param [Object] resource to write.
      # @param [Serializer] serializer used to write the resource state.
      # @yield (builder)
      # @yieldparam [ResourceBuilder] builder used write the resources fields
      #     and meta.
      #
      # @return [void]
      def resource( resource, serializer = nil, &block )
        output[:data] = build_resource( resource, serializer, &block )
      end

      # Output a single resource as the response data.
      #
      # @param [Enumerable<Object>] resources to write.
      # @param [Serializer] serializer used to write the resource state.
      # @yield (builder, resource)
      # @yieldparam [ResourceBuilder] builder used write the resources fields
      #     and meta.
      # @yieldparam [Object] resource being written.
      # @return [void]
      def resources( collection, serializer = nil, &block )
        output[:data] =
          collection.map do |resource|
            build_resource resource, serializer, &block
          end
      end

      # @overload error( exception, http_status = nil )
      #   @param (see ErrorBuilder#exception)
      # @overload error( &block )
      #   @yield (builder)
      #   @yieldparam [ErrorBuilder] builder used to describe the error.
      #
      # @return [void]
      def error( exception = nil, http_status = nil, &block )
        builder = ErrorBuilder.new

        if block_given?
          yield builder
        else
          builder.exception( exception, http_status )
        end

        errors = ( output[:errors] ||= [] )
        errors << builder.compile
      end

      # (see BaseBuilder#compile)
      def compile
        @compiled ||= begin
          compiled = output.dup
          compiled[:jsonapi] = { version: "1.0" }

          while context.included_resources?
            included = ( compiled[ :included ] ||= [] )
            context.collect_included_resources.each do |resource, options|
              included << build_resource( resource, options[:serializer], &options[:block] )
            end
          end

          compiled
        end
      end

      def to_json
        compile.to_json
      end

      def to_s
        compile.to_s
      end

      private :identifier

      private

        def build_resource( resource, serializer, &block )
          fail "A block is required if no serializer is given" if !serializer && !block_given?

          builder = ResourceBuilder.new( context )
          if serializer
            serializer.serialize( builder )
          else
            yield builder
          end

          builder.compile
        end

    end
  end
end