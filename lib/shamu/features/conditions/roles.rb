module Shamu
  module Features
    module Conditions

      # Match against the current user's roles.
      class Roles < Conditions::Condition

        # (see Condition#match?)
        def match?( context )
          ( context.roles && roles ).any?
        end

        private

          def roles
            @roles ||= Array( config )
          end

      end

    end
  end
end