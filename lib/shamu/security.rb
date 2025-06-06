module Shamu
  # {include:file:lib/shamu/security/README.md}
  module Security
    require "shamu/security/error"
    require "shamu/security/principal"
    require "shamu/security/context"
    require "shamu/security/delegate_principal"
    require "shamu/security/policy"
    require "shamu/security/policy_rule"
    require "shamu/security/no_policy"
    require "shamu/security/redacted_list"
    require "shamu/security/support"
    require "shamu/security/roles"
    require "shamu/security/role_entity"
    require "shamu/security/roles_service"
    require "shamu/security/hashed_value"

    # See {.private_key}
    ENV_PRIVATE_KEY = "SHAMU_PRIVATE_KEY".freeze

    # @!attribute
    #
    # A strong key used to authenticate (not encrypt) input from untrusted
    # sources (such as cookies, headers, etc).
    #
    # If the key has not been {#private_key= set then shamu will look for an
    # environment variable named SHAMU_PRIVATE_KEY.
    #
    # ## To generate a strong key
    #
    # ```
    # # 1024-bit private key
    # key = SecureRandom.base64( 128 )
    # ```
    # @return [String]
    def self.private_key
      @private_key ||=
        begin
          key = ENV[ENV_PRIVATE_KEY].presence

          if defined? ::Rails
            key ||= ::Rails.application.credentials[:private_key].presence
            key ||= ::Rails.application.credentials[:secret_key_base].presence
          end

          if key.blank?
            raise("No private key configured. Set Shamu::Security.private_key or add an the #{ENV_PRIVATE_KEY} environment variable to the host.")
          end

          key
        end
    end

    # @param [String] key to use.
    # @return [String]
    def self.private_key=(key)
      @private_key = key && Base64.decode64(key)
    end
  end
end
