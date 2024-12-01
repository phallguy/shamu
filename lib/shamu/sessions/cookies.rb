module Shamu
  module Sessions
    # Exposes a persistent key/value store to track state across multiple
    # requests.
    module Cookies
      def self.create(scorpion, *args, &block)
        if defined? Shamu::Rails::Cookies
          return scorpion.fetch(Shamu::Rails::Cookies, *args, &block)
        elsif defined? ::Rack
          return scorpion.fetch(Shamu::Rack::Cookies, *args, &block)
        end

        raise("Configure a Shamu::Sessions::CookiesStore in your scorpion setup.")
      end

      # Fetch the value with the given key from the store. If they key does not
      # yet exist, yields to the block and caches the result.
      #
      # @param [String] key
      # @yieldreturn The calculated value of the key.
      # @return [Object]
      def get(key)
        raise(NotImplementedError)
      end

      # @param [String] name
      # @return [Boolean] true if the cookie has been set.
      def key?(name)
        raise(NotImplementedError)
      end

      # Save a named value in the session.
      #
      # @param [String] key
      # @param [Object] value. Must be a primitive (String, Number, Hash, Array).
      # @return [value]
      def set(key, value)
        raise(NotImplementedError)
      end

      # Remove the value with the given key.
      # @param [String] key
      # @return [nil]
      def delete(key)
        raise(NotImplementedError)
      end
    end
  end
end
