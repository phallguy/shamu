module Shamu
  module Features
    module Conditions

      # Match against an environment variable.
      class Env < Conditions::Condition

        # (see Condition#match?)
        def match?( context )
          variables.any? { |name, matcher| matcher.call( context.env( name ) ) }
        end

        private

          def variables
            @variables ||= hash_variables || array_variables
          end

          def hash_variables
            return unless config.is_a?( Hash )

            config.each_with_object( {} ) do |(name, value), hash|
              hash[name] = ->(v) { v == value }
            end
          end

          def array_variables
            Array( config ).each_with_object( {} ) do |name, hash|
              hash[name] = ->(v) { v.to_bool }
            end
          end

      end

    end
  end
end