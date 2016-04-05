module Shamu
  module JsonApi

    # Build a JSON API response from one or more resources.
    class Response < BaseBuilder

      # Output a single resource as the response data.
      # @param [Object] resource to write.
      # @param [Presenter] presenter used to write the resource state.
      # @yield (builder)
      # @yieldparam [ResourceBuilder] builder used write the resources fields
      #     and meta.
      #
      # @return [self]
      def resource( resource, presenter = nil, &block )
        output[:data] = build_resource( resource, presenter, &block )
        self
      end

      # Output a multiple resources as the response data.
      #
      # @param [Enumerable<Object>] resources to write.
      # @param [Presenter] presenter used to write the resource state.
      # @yield (builder, resource)
      # @yieldparam [ResourceBuilder] builder used write the resources fields
      #     and meta.
      # @yieldparam [Object] resource being written.
      # @return [self]
      def collection( collection, presenter = nil, &block )
        output[:data] =
          collection.map do |resource|
            build_resource resource, presenter, &block
          end
        self
      end

      # @overload error( exception, http_status = nil )
      #   @param (see ErrorBuilder#exception)
      # @overload error( &block )
      #   @yield (builder)
      #   @yieldparam [ErrorBuilder] builder used to describe the error.
      #
      # @return [self]
      def error( exception = nil, http_status = nil, &block )
        builder = ErrorBuilder.new

        if block_given?
          yield builder
        elsif exception.is_a?( Exception )
          builder.exception( exception, http_status )
        else
          http_status ||= 500
          builder.summary http_status, http_status.to_s, exception
        end

        errors = ( output[:errors] ||= [] )
        errors << builder.compile

        self
      end

      # (see BaseBuilder#compile)
      def compile
        @compiled ||= begin
          compiled = output.dup
          compiled[:jsonapi] = { version: "1.0" }
          if params_meta = context.params_meta
            compiled[:meta] ||= {}
            compiled[:meta].reverse_merge!( params_meta )
          end

          while context.included_resources?
            included = ( compiled[ :included ] ||= [] )
            context.collect_included_resources.each do |resource, options|
              included << build_resource( resource, options[:presenter], &options[:block] )
            end
          end

          compiled
        end
      end

      # @return [Hash] the compiled resources.
      def as_json( * )
        compile.as_json
      end

      # @return [String]
      def to_json( * )
        compile.to_json
      end

      # @return [String]
      def to_s
        to_json
      end

      # Responses don't have identifiers
      undef :identifier

      private

        def build_resource( resource, presenter, &block )
          presenter = context.find_presenter( resource ) if !presenter && !block_given?

          builder = ResourceBuilder.new( context )
          if presenter
            presenter.present( resource, builder )
          else
            yield builder
          end

          builder.compile
        end

    end
  end
end