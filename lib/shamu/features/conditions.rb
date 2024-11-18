module Shamu
  module Features
    # Conditions that must match for a {Selector} to enable a {Toggle}.
    module Conditions
      require "shamu/features/conditions/condition"

      require "shamu/features/conditions/env"
      require "shamu/features/conditions/hosts"
      require "shamu/features/conditions/matching"
      require "shamu/features/conditions/not_matching"
      require "shamu/features/conditions/percentage"
      require "shamu/features/conditions/proc"
      require "shamu/features/conditions/roles"
      require "shamu/features/conditions/schedule_at"
    end
  end
end