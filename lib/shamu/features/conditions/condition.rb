module Shamu
  module Features
    module Conditions

      # A condition that must be met for a {Selector} to match and enable a
      # {Toggle}.
      class Condition

        # @param [String] name of the condition.
        # @param [Object] config settings for the condition.
        def self.create( name, config, toggle )
          @condition_class ||= Hash.new do |hash, key|
            hash[key] = "Shamu::Features::Conditions::#{ key.to_s.camelize }".constantize
          end

          @condition_class[name].new config, toggle
        end

        # @param [Object] config options selected for the condition.
        def initialize( config, toggle )
          @config = config
          @toggle = toggle
        end

        # @param [Context] context the feature evaluation context.
        # @return [Boolean] true if the condition matches the given environment.
        def match?( context )
          fail NotImplementedError
        end

        private

          attr_reader :config
          attr_reader :toggle
      end

    end
  end
end