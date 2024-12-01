module Shamu
  module Rails
    # Expose the request cookies as a hash.
    class Cookies
      # @return [Cookies]
      def self.create(*)
        raise("Add Shamu::Rails::CookiesMiddleware to use Shamu::Rails::Cookies")
      end

      # @param [Hash] env the Rack environment
      def initialize(request)
        @request = request
      end

      # Get a cookie value from the browser.
      # @param [String] key or name of the cookie
      # @return [String] cookie value
      def get(key)
        request.cookie_jar[key]
      end
      alias [] get

      # @param [String] name
      # @return [Boolean] true if the cookie has been set.
      def key?(name)
        request.cookie_jar.key?(name)
      end

      # Set or update a cookie in the headers.
      #
      # @overload set( key, value )
      #   @param [String] key or name of the cookie
      #   @param [String] value to assign
      #
      # @overload set( key, hash )
      #   @param [String] key or name of the cookie
      #   @option hash [String] :value
      #   @option hash [String] :domain
      #   @option hash [String] :path
      #   @option hash [Integer] :max_age
      #   @option hash [Time] :expires
      #   @option hash [Boolean] :secure
      #   @option hash [Boolean] :http_only
      #
      # @return [self]
      def set(key, value)
        value = { value: value } unless value.is_a?(Hash)
        value[:signed] = false unless value.key?(:signed)

        request.cookie_jar[key] = value

        self
      end
      alias []= set

      # Delete a cookie from the browser.
      # @param [String] key or name of the cookie.
      # @return [self]
      def delete(key)
        request.cookie_jar.delete(key)
        self
      end

      private

        attr_reader :request
    end
  end
end