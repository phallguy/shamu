require "scorpion/rack"

module Shamu
  module Rack

    # Expose a {QueryParams} hash to any service that wants to toggle behavior
    # based on query parameters.
    class QueryParamsMiddleware
      include Scorpion::Rack

      def initialize( app )
        @app = app
      end

      def call( env )
        query_params = Shamu::Rack::QueryParams.new( env )
        scorpion( env ).hunt_for Shamu::Rack::QueryParams, return: query_params

        @app.call( env )
      end

    end
  end
end