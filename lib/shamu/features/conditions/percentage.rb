module Shamu
  module Features
    module Conditions

      # Match against a limited percentage of total users.
      class Percentage < Conditions::Condition

        # (see Condition#match?)
        def match?( context )
          if context.user_id
            ( user_id_hash( context.user_id ) ^ toggle_hash ) % percentage == 0
          else
            context.sticky!
            Random.rand( 100 ) < percentage
          end
        end

        private

          def percentage
            @percentage ||= [ config.to_i, 100 ].min
          end

          def user_id_hash( user_id )
            if user_id.is_a?( Numeric )
              return user_id
            else
              return user_id.sub( "-", "" ).to_i( 16 )
            end
          end

          def toggle_hash
            # Use the name of the toggle to provide consistent semi-random noise
            # into the user selection process.
            @toggle_hash ||= toggle.name.sub( /[^a-z]/, "" ).last( 11 ).to_i( 36 )
          end

      end

    end
  end
end