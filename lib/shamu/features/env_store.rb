module Shamu
  module Features

    # Expose a read-only runtime environment for consumption by the
    # {FeaturesService}. By default blends a Rack env request headers (if using
    # Rack) with the host env. The request env overrides the host.
    #
    # When {#fetch fetching}, EnvStore will look for an `X-Shamu-Features` header
    # sent in the HTTP request. It should be constructed using {.pack} to
    # build a verifiable hash of feature settings.
    #
    # If a rack value is not set, EnvStore will fall back to looking for the
    # toggle in the host's environment with the name `TOGGLE_{ toggle name
    # upcased and underscored }`. For example `buy_now/one_click` will look for
    # `TOGGLE_BUY_NOW_ONE_CLICK` in the environment.
    class EnvStore < Services::Service

      RACK_ENV_KEY      = "HTTP_X_SHAMU_FEATURES".freeze
      RACK_PARAMS_KEY   = "shamu.features".freeze
      RACK_PARAMS_FEATURES_KEY = "shamu.features.from_params".freeze
      RACK_HEADER_FEATURES_KEY = "shamu.features.from_header".freeze

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [ToggleCode] code used to pack and unpack the features.
      attr_dependency :codec, ToggleCodec

      #
      # @!endgroup Dependencies

      # Fetch a value from the environment.
      def fetch( key, &block )
        return env_fetch( key, &block ) unless defined? Rack

        rack_params_fetch( key, &block )
      end

      # @return [String] the expected ENV key name for the given toggle name.
      def self.env_key_name( key )
        key = key.upcase
        key.tr! "/", "_"
        key
      end

      private

        def env_fetch( key, &block )
          key = self.class.env_key_name( key )
          if ENV.key?( key )
            ENV[ key ].to_bool
          elsif block_given?
            yield
          end
        end

        def rack_header_fetch( key, &block )
          rack_env = scorpion.fetch( Scorpion::Rack::Env )
          return env_fetch( key, &block ) unless header = rack_env[RACK_ENV_KEY]

          features = rack_env.fetch( RACK_HEADER_FEATURES_KEY ) do
            rack_env[ RACK_HEADER_FEATURES_KEY ] = codec.unpack( header )
          end

          features.fetch( key ) do
            env_fetch( key, &block )
          end
        end

        def rack_params_fetch( key, &block )
          rack_env = scorpion.fetch( Scorpion::Rack::Env )
          request  = ::Rack::Request.new( rack_env )

          return rack_header_fetch( key, &block ) unless param = request.params[ RACK_PARAMS_KEY ]

          features = rack_env.fetch( RACK_PARAMS_FEATURES_KEY ) do
            rack_env[ RACK_PARAMS_FEATURES_KEY ] = codec.unpack( param )
          end

          features.fetch( key ) do
            rack_header_fetch( key, &block )
          end
        end

    end
  end
end
