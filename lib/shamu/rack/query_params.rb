module Shamu
  module Rack
    # Expose the query string and post data parameters as a hash.
    class QueryParams
      # @return [QueryParams]
      def self.create(*)
        raise("Add Shamu::Rack::QueryParamsMiddleware to use Shamu::Rack::QueryParams")
      end

      # @param [Hash] env the Rack environment
      def initialize(env)
        @env = env
      end

      # Get a cookie value from the browser.
      # @param [String] key or name of the cookie
      # @return [String] cookie value
      def get(key)
        key = key.to_s
        env_query_params[key]
      end
      alias [] get

      # @param [String] name
      # @return [Boolean] true if the cookie has been set.
      def key?(name)
        env_query_params.key?(name.to_s)
      end

      private

        attr_reader :env

        def env_query_params
          @env_query_params ||= ::Rack::Request.new(env).params
        end
    end
  end
end