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

      # @overload error( exception )
      #   @param (see ErrorBuilder#exception)
      # @overload error( &block )
      #   @yield (builder)
      #   @yieldparam [ErrorBuilder] builder used to describe the error.
      #
      # @return [self]
      def error( error = nil, &block )
        builder = ErrorBuilder.new

        if error.is_a?( Exception )
          builder.exception( error )
        elsif error
          builder.title error
        end

        yield builder if block_given?

        errors = ( output[:errors] ||= [] )
        errors << builder.compile

        self
      end

      # Write ActiveModel validation errors to the response.
      #
      # @param [#errors] record an object that responds to `#errors` and returns
      #     a map from fields to error messages.
      # @yield ( builder, attr, message )
      # @yieldparam [ErrorBuilder] builder the builder for this error message.
      # @yieldparam [String] attr the attribute with a validation error.
      # @yieldparam [String] message the error message.
      # @return [self]
      def validation_errors( record, &block )
        record.errors.each do |attr, message|
          error message do |builder|
            path = "/data"
            path << "/attributes/#{ attr }" unless attr == :base
            builder.pointer path

            yield builder, attr, message if block_given?
          end
        end
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