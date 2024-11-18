module Shamu
  module JsonApi
    # Used by a {Serilaizer} to write fields and relationships
    class BaseBuilder
      # @param [Context] context the current serialization context.
      def initialize(context)
        @context = context
        @output = {}
      end

      include BuilderMethods::Link
      include BuilderMethods::Meta

      # @return [Hash] the results output as JSON safe hash.
      def compile
        output
      end

      private

        # @!attribute
        # @return [Hash] output hash.
        attr_reader :output

        # @!attribute
        # @return [Context] the JSON serialization context.
        attr_reader :context
    end
  end
end
