module Shamu
  module Features
    # ...
    class FeaturesService < Services::Service
      include Security::Support

      SESSION_KEY = "shamu.toggles".freeze

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [Shamu::Sessions::SessionStore]
      #
      # A persistent storage for a user session where the feature service can
      # persist sticky feature toggles.
      attr_dependency :session_store, Shamu::Sessions::SessionStore

      # @!attribute
      # @return [Shamu::Features::ToggleCodec]
      #
      # Used to pack and unpack sticky toggle overrides in a persistent user
      # session.
      attr_dependency :toggle_codec, Shamu::Features::ToggleCodec

      # @!attribute
      # @return [Shamu::Features::EnvStore]
      #
      # Read-only access to Rack and host ENV toggle overrides.
      attr_dependency :env_store, Shamu::Features::EnvStore

      # @!attribute
      # @return [Shamu::Logger]
      attr_dependency :logger, Shamu::Logger

      #
      # @!endgroup Dependencies

      # @!method initialize( config_path )
      # @param
      # @return [FeaturesService]
      def initialize(config_path = nil)
        @config_path = config_path || self.class.default_config_path

        super()
      end

      # Indicates if the feature is enabled for the current request/session.
      #
      # @param [String] name of the feature.
      # @return [Boolean] true if the feature is enabled.
      def enabled?(name)
        context = build_context

        if toggle = toggles[name]
          resolve_known(toggle, context)
        else
          resolve_unknown(name)
        end
      end

      # List all the known toggles with the given prefix.
      # @param [String] name prefix
      # @return [Hash] the known toggles.
      def list(prefix = nil)
        if prefix.present?
          toggles.each_with_object({}) do |(name, toggle), result|
            next unless name.start_with?(prefix)

            result[name] = toggle
          end
        else
          toggles.dup
        end
      end

      private

        attr_reader :config_path

        def toggles
          @toggles ||= if File.exist?(config_path)
                         if ::Rails.env.development?
                           require "listen"
                           listener = Listen.to(File.dirname(config_path), only: File.basename(config_path)) do
                             @toggles = Toggle.load(config_path)
                           end
                           listener.start
                         end

                         Toggle.load(config_path)
                       else
                         logger.warn("Feature configuration file does not exist: #{config_path}")
                         {}
                       end
        end

        def resolve_unknown(name)
          logger.info("The '#{name}' feature toggle has not been configured. Add to #{config_path}.")
          false
        end

        def resolve_known(toggle, context)
          raise(RetiredToggleError.new(toggle)) if toggle.retired?(context)

          store_value = resolve_store_toggle(toggle)
          return store_value unless store_value.nil?

          resolve_toggle(toggle, context)
        end

        def build_context
          Features::Context.new(self,
                                scorpion: scorpion,
                                user_id: security_principal.user_id,
                                roles: roles_service.roles_for(security_principal.user_id, security_context))
        end

        def resolve_toggle(toggle, context)
          toggle.enabled?(context).tap do |result|
            persist_sticky(toggle.name, result) if context.sticky?
          end
        end

        def resolve_store_toggle(toggle)
          # session_store is for sticky overrides
          sticky_overrides.fetch(toggle.name) do
            # env_store is for host and service header overrides
            env_store.fetch(toggle.name)
          end
        end

        def persist_sticky(name, result)
          sticky_overrides[name] = result
          session_store.set(SESSION_KEY, toggle_codec.pack(sticky_overrides))
        end

        def sticky_overrides
          @sticky_overrides ||= if token = session_store.fetch(SESSION_KEY)
                                  toggle_codec.unpack(token)
                                else
                                  {}
                                end
        end

        class << self
          # Looks for a config/features.yml or features.yml in the current
          # directory. Use {#ddefault_config_path=} to manually set the default
          # config file.
          #
          # @return [String] the default path to load toggle information from.
          def default_config_path
            @default_config_path ||= begin
              path = File.expand_path("config/features.yml")
              path = File.expand_path("features.yml") unless File.exist?(path)
              path
            end
          end

          # @param [String] path of the default config file.
          # @return [String]
          def default_config_path=(path)
            @default_config_path = path
          end
        end
    end
  end
end
