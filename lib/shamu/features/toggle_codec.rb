module Shamu
  module Features
    # Packs and unpacks sticky toggle settings in a securely verifiable way. The
    # data is not encrypted so it should not be relied on for security. It only
    # guarantees that the packed data was created by calling
    # {ToggleCode#pack}.
    class ToggleCodec
      include Shamu::Security::HashedValue

      # @param [String] private_key the private key used to verify the packed toggles.
      def initialize(private_key = Shamu::Security.private_key)
        @private_key = private_key
      end

      # Packs a hash of configured features into a string that can be sent
      # from a client at a later date to override those features. Use
      # {#unpack} to restore the features hash.
      #
      # @param [Hash<String,Boolean>] featues hash of name to enabled state.
      # @return [String] the packed string.
      def pack(toggles)
        hash_value(insecure_pack(toggles))
      end

      # Packs a hash of configured features without any authentication
      # guarantees. Useful for working with trusted sources such as ENV
      # variables.
      #
      # @param [Hash<String,Boolean>] featues hash of name to enabled state.
      # @return [String] the packed string.
      def insecure_pack(toggles)
        toggles.each_with_object("") do |(key, state), packed|
          packed << "," if packed.present?
          packed << "!" unless state
          packed << key
        end
      end

      # Unpack a {#pack packed} token into its original hash of configured
      # toggles. If the token is invalid or unauthenticated an empty result is
      # returned.
      #
      # @param [String] token the packed toggles
      # @return [Hash<String,Boolean>] the configured toggles.
      def unpack(token)
        insecure_unpack(verify_hash(token))
      end

      # Unpack a {#insecure_pack insecure packed} token into its original hash
      # of configured toggles. If the token is invalid an empty result is
      # returned.
      #
      # @param [String] token the packed toggles
      # @return [Hash<String,Boolean>] the configured toggles.
      def insecure_unpack(token)
        return {} unless token

        token.split(",").each_with_object({}) do |toggle, hash|
          bang = toggle[0] == "!"
          key  = bang ? toggle[1..-1] : toggle

          hash[key] = !bang
        end
      end
    end
  end
end
