require "crc32"

module Shamu
  module Features
    module Conditions
      # Match against a limited percentage of total users.
      class Percentage < Conditions::Condition
        # (see Condition#match?)
        def match?(context)
          if context.user_id
            (user_id_hash(context.user_id) ^ toggle_crc) % 100 < percentage
          else
            context.sticky!
            Random.rand(100) < percentage
          end
        end

        private

          def percentage
            @percentage ||= [config.to_i, 100].min
          end

          def user_id_hash(user_id)
            if user_id.is_a?(Numeric)
              user_id
            else
              user_id.sub("-", "").to_i(16)
            end
          end

          def toggle_crc
            # Use the name of the toggle to provide consistent semi-random noise
            # into the user selection process.
            @toggle_crc ||= Crc32.calculate(toggle.name, toggle.name.length, 0)
          end
      end
    end
  end
end
