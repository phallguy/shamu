module Shamu
  module Sessions

    # Exposes a persistent key/value store to track state across multiple
    # requests.
    module SessionStore

      def self.create( scorpion, *args, &block )
        return scorpion.fetch Shamu::Sessions::CookieStore, *args, &block if defined? Rack

        fail "Configure a Shamu::Sessions::SessionStore in your scorpion setup."
      end

      # Fetch the value with the given key from the store. If they key does not
      # yet exist, yields to the block and caches the result.
      #
      # @param [String] key
      # @yieldreturn The calculated value of the key.
      # @return [Object]
      def fetch( key, &block )
        fail NotImplementedError
      end

      # Save a named value in the session.
      #
      # @param [String] key
      # @param [Object] value. Must be a primitive (String, Number, Hash, Array).
      # @return [value]
      def set( key, value )
        fail NotImplementedError
      end

      # Remove the value with the given key.
      # @param [String] key
      # @return [nil]
      def delete( key )
        fail NotImplementedError
      end

    end
  end
end
