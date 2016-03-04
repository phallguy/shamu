require "openssl"

module Shamu
  module Security

    # Adds support for hashing and verifying a string value.
    #
    # ```ruby
    # class Codec
    #   include Shamu::Security::HashedValue
    #
    #   def initialize( private_key = Shamu::Security.private_key )
    #     @private_key = private_key
    #   end
    #
    #   def store( value )
    #     hash_value( value )
    #   end
    #
    #   def restore( hashed )
    #     verify_hash( hashed )
    #   end
    # end
    #
    # codec = Codec.new
    # signed = codec.store "example"  # => "0123456789abcdef0123456789abcdef012345678;example"
    # codec.restore signed            # => "example"
    # codec.restore "example"         # => nil
    # ```
    module HashedValue

      private

        # @!visiblity public
        # @return [String] the private key used to sign the hashes.
        attr_reader :private_key

        # @!visibility public
        #
        # @param [String] string to hash.
        # @return [String] packed string with hash and original value.
        def hash_value( string )
          return nil unless string
          "#{ hash_digest( string ) }$#{ string }"
        end

        def hash_digest( string )
          alg = OpenSSL::Digest::SHA1.new
          OpenSSL::HMAC.hexdigest( alg, private_key, string )
        end

        # @!visiblity public
        #
        # Verify that the hashed value has not been modified.
        #
        # @param [String] hashed value returned from {#hash_value}.
        # @return [String] the original value.
        def verify_hash( hashed )
          return unless hashed
          return if hashed.length < 41

          mac     = hashed[ 0...40 ]
          toggles = hashed[ 41..-1 ]

          return unless hash_digest( toggles ) == mac

          toggles
        end
    end
  end
end
