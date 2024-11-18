require "scorpion/rack"

module Shamu
  module Rack
    # Expose a {Cookies} hash to any service that wants to use session specific
    # storage.
    class CookiesMiddleware
      include Scorpion::Rack

      def initialize(app)
        @app = app
      end

      def call(env)
        cookies = Shamu::Rack::Cookies.new(env)
        scorpion(env).hunt_for(Shamu::Rack::Cookies, return: cookies)

        status, headers, body = @app.call(env)

        [status, cookies.apply!(headers), body]
      end
    end
  end
end