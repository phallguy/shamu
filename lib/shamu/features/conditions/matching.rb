module Shamu
  module Features
    module Conditions

      # Match if another feature is also enabled.
      class Matching < Conditions::Condition

        # (see Condition#match?)
        def match?( context )
          context.enabled?( config )
        end
      end

    end
  end
end