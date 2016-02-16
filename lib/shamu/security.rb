module Shamu
  # {include:file:lib/shamu/security/README.md}
  module Security
    require "shamu/security/error"
    require "shamu/security/principal"
    require "shamu/security/policy"
    require "shamu/security/policy_rule"
    require "shamu/security/no_policy"
    require "shamu/security/support"
    require "shamu/security/roles"
  end
end