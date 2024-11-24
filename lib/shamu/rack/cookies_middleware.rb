# frozen_string_literal: true

require "scorpion/rack"

module Shamu
  module Rack
    # Expose a {Cookies} hash to any service that wants to use session specific
    # storage.
    class CookiesMiddleware
      include Scorpion::Rack

      ENV_KEY = "shamu.cookies"

      def initialize(app)
        @app = app
      end

      def call(env)
        cookies = env[ENV_KEY]
        cookies ||= Shamu::Rack::Cookies.new(env)
        scorpion(env).hunt_for(Shamu::Rack::Cookies, return: cookies)

        status, headers, body = @app.call(env)

        [status, cookies.apply!(headers), body]
      end
    end
  end
end