module Shamu
  module Rack

    # Expose the request cookies as a hash.
    class Cookies

      # @return [Cookies]
      def self.create( * )
        fail "Add Shamu::Rack::CookiesMiddleware to use Shamu::Rack::Cookies"
      end

      # @param [Hash] env the Rack environment
      def initialize( env )
        @env = env
        @cookies = {}
        @deleted_cookies = []
      end

      # Apply the cookies {#set} or {#delete deleted} to the actual rack
      # response headers.
      #
      # Modifies the `headers` hash!
      #
      # @param [Hash] headers from rack response
      # @return [Hash] the modified headers with cookie values.
      def apply!( headers )
        cookies.each do |key, value|
          ::Rack::Utils.set_cookie_header! headers, key, value
        end

        deleted_cookies.each do |key|
          ::Rack::Utils.delete_cookie_header! headers, key
        end

        headers
      end

      # Get a cookie value from the browser.
      # @param [String] key or name of the cookie
      # @return [String] cookie value
      def get( key )
        key = key.to_s

        if cookie = cookies[ key ]
          cookie[:value]
        else
          env_cookies[ key ]
        end
      end
      alias_method :[], :get

      # @param [String] name
      # @return [Boolean] true if the cookie has been set.
      def key?( name )
        cookies.key?( name ) || env_cookies.key?( name )
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
      def set( key, value )
        key = key.to_s
        deleted_cookies.delete( key )

        value = { value: value } unless value.is_a? Hash
        cookies[key] = value

        self
      end
      alias_method :[]=, :set

      # Delete a cookie from the browser.
      # @param [String] key or name of the cookie.
      # @return [self]
      def delete( key )
        cookies.delete( key )
        @deleted_cookies << key if env_cookies.key?( key )
        self
      end

      private

        attr_reader :env
        attr_reader :cookies
        attr_reader :deleted_cookies

        def env_cookies
          @env_cookies ||= begin
            @env_cookies = {}
            string = env[ "HTTP_COOKIE" ]

            # Cribbed from Rack::Request#cookies
            parsed = ::Rack::Utils.parse_query( string, ";," ) { |s| ::Rack::Utils.unescape( s ) rescue s } # rubocop:disable Style/RescueModifier
            parsed.each do |k, v|
              @env_cookies[ k ] = Array === v ? v.first : v
            end
          end
        end
    end
  end
end