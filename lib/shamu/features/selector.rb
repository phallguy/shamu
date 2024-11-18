module Shamu
  module Features
    # A selector used to match conditions against environment configuration.
    class Selector
      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Array<Condition>] conditions that must match for the selector
      #     to match.
      attr_reader :conditions

      # @!attribute
      # @return [Boolean] true if the feature should not be enabled when the
      #     selector matches.
      attr_reader :reject

      # @!attribute
      # @return [Toggle] that owns the selector.
      attr_reader :toggle

      #
      # @!endgroup Attributes

      def initialize(toggle, config)
        @conditions = []

        config.each do |name, condition_config|
          if name == "reject"
            @reject = condition_config.to_bool
          else
            @conditions << Conditions::Condition.create(name, condition_config, toggle)
          end
        end

        @conditions.freeze
      end

      # @param [Context] context the feature evaluation context.
      # @return [Boolean] true if the selector matches the given environment.
      def match?(context)
        conditions.all? { |c| c.match?(context) }
      end
    end
  end
end