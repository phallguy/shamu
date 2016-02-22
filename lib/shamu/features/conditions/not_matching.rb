module Shamu
  module Features
    module Conditions

      # Match if another feature is also enabled.
      class NotMatching < Conditions::Matching

        # (see Condition#match?)
        def match?( context )
          !super
        end
      end

    end
  end
end