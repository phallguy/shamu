require "shamu/rack/cookies"

module Shamu
  module Sessions
    # Track persistent values in a cookie stored on the user's machine. Values
    # kept in the CookieStore are not encrypted but they are protected by HMAC
    # hashing to ensure that they have not been modified.
    #
    # To support cookies, in your service it must be instantiated as part of a
    # Rack request and you must add {Shamu::Rack::CookieMiddleware} to your app.
    #
    # ## Adding support to a Rails app
    #
    # ```
    # # application.rb
    #
    # config.middleware.use Shamu::Rack::CookiesMiddleware
    # ```
    #
    # ## In a standalone Rack app
    #
    # ```
    # require "shamu/rack"
    #
    # app = Rack::Builder.new do
    #   use Shamu::Rack::CookiesMiddleware
    #
    # end
    #
    # run app
    # ```
    class CookieStore < Services::Service
      include Sessions::SessionStore

      # How long cookies should be kept.
      TTL = (30 * 24 * 60 * 60)

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [Shamu::Rack::Cookies]
      attr_dependency :cookies, Shamu::Sessions::Cookies

      #
      # @!endgroup Dependencies
      #

      # @param [String] private_key the private key used to verify cookie
      #     values.
      def initialize(private_key = Shamu::Security.private_key)
        @private_key = private_key

        super()
      end

      # (see SessionStore#fetch)
      def fetch(key)
        if cookies.key?(key)
          cookies.get(key)
        elsif block_given?
          yield
        end
      end

      # (see SessionStore#set)
      def set(key, value)
        value =
          if value.is_a?(Hash)
            value.merge(value: value[:value])
          else
            {
              value: value,
            }
          end

        cookies.set(key, secure: true, max_age: TTL, **value)
      end

      # (see SessionStore#delete)
      def delete(key)
        cookies.delete(key)
      end
    end
  end
end
