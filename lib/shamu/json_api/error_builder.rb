require "rack"

module Shamu
  module JsonApi
    # Build an error response object.
    class ErrorBuilder
      def initialize
        @output = {}
      end

      include BuilderMethods::Link
      include BuilderMethods::Meta

      # @param [String] id unique id for this occurrence of the error.
      # @return [self]
      def id(id)
        output[:id] = id
        self
      end

      # Summarize an exception as an error.
      # @param [Exception] exception
      # @return [self]
      def exception(exception)
        name = exception.class.name.demodulize.gsub(/Error$/, "")
        code(name.underscore)
        title(name.titleize)
        detail(exception.message)

        self
      end

      # Set an HTTP status code related to the error.
      # @param [Symbol,Integer] status code.
      # @return [self]
      def http_status(status)
        status = ::Rack::Utils.status_code(status) if status.is_a?(Symbol)
        output[:status] = status.to_s
        self
      end

      # Set an application specific error code.
      # @return [self]
      def code(code)
        output[:code] = code.to_s
        self
      end

      # Set a short human readable title of the error.
      # @return [self]
      def title(title)
        output[:title] = title.to_s
        self
      end

      # @return [String] message details about the error.
      # @return [self]
      def detail(message)
        output[:detail] = message
        self
      end

      # JSON pointer to the associated document in the request that was the
      # source of the pointer.
      # @return [self]
      def pointer(pointer)
        output[:source] ||= {}
        output[:source][:pointer] = pointer
        self
      end

      # The name of the parameter that caused the error.
      # @return [self]
      def parameter(name)
        output[:source] ||= {}
        output[:source][:parameter] = name
        self
      end

      # @return [Hash] the results output as JSON safe hash.
      def compile
        output
      end

      private

        attr_reader :output
    end
  end
end