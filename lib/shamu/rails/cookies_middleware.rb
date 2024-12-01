# frozen_string_literal: true

require "scorpion/rack"

module Shamu
  module Rails
    # Expose a {Cookies} hash to any service that wants to use session specific
    # storage.
    class CookiesMiddleware
      include Scorpion::Rack

      ENV_KEY = "shamu.cookies"

      def initialize(app)
        @app = app
      end

      def call(env)
        cookies = env[ENV_KEY] ||=
          begin
            request = ActionDispatch::Request.new(env)
            Shamu::Rails::Cookies.new(request)
          end
        scorpion(env).hunt_for(Shamu::Rails::Cookies, return: cookies)

        @app.call(env)
      end
    end
  end
end
