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
      include Shamu::Security::HashedValue

      # How long cookies should be kept.
      TTL = ( 30 * 24 * 60 * 60 ).freeze

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [Shamu::Rack::Cookies]
      attr_dependency :cookies, Shamu::Rack::Cookies

      #
      # @!endgroup Dependencies
      #

      # @param [String] private_key the private key used to verify cookie
      #     values.
      initialize do |private_key = Shamu::Security.private_key, **|
        @private_key = private_key
      end

      # (see SessionStore#fetch)
      def fetch( key, &block )
        if cookies.key?( key )
          verify_hash( cookies.get( key ) )
        elsif block_given?
          yield
        end
      end

      # (see SessionStore#set)
      def set( key, value )
        cookies.set( key, value: hash_value( value ), secure: true, max_age: TTL )
      end

      # (see SessionStore#delete)
      def delete( key )
        cookies.delete( key )
      end

    end
  end
end
