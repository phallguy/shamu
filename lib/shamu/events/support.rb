module Shamu
  module Events
    # Add event dispatching support to a {Services::Service}
    module Support
      extend ActiveSupport::Concern

      included do
        # ============================================================================
        # @!group Dependencies
        #

        # @!attribute
        # @return [Events::EventsService] the events service to publish messages
        #     to.
        attr_dependency :events_service, Events::EventsService

        #
        # @!endgroup Dependencies
      end

      # (see Support.event_channel)
      def event_channel
        self.class.event_channel
      end

      private

        # @!visibility public
        #
        # Publish the given `message` to the {#events_service}.
        #
        # @param [Events::Message, Symbol] message the custom event specific message to
        #     publish.
        # @param [String] channel to publish to.
        # @param [Hash] message_attrs arguments to use when creating an
        # instance of `message`.
        #
        # If `message` is a symbol, looks for a {Message} class in
        # {ServiceNamespace}::{OptionalServiceDomain}Events::{name.caemlize}.
        # @return [void]
        def event!(message, channel: event_channel, **message_attrs)
          if message.is_a?(Symbol)
            message = self.class
                          .event_message_namespace
                          .const_get(message.to_s.camelize)
                          .new(message_attrs)
          end
          events_service.publish(channel, message)
        end

        class_methods do
          # @!visibility public
          #
          # The channel to {#publish_event publish events} to. Defaults to the
          # transformed name of the service class.
          #
          #     Users::UsersService              => users
          #     Users::ProfileService            => users/profile
          #     Users::Profiles::ProfilesService => users/profiles
          #
          # @return [String] the name of the channel.
          def event_channel
            @event_channel ||= begin
              base_name = name || "Events"
              parts     = base_name.split("::")
              parts[-1].sub!(/Service$/, "")
              parts.pop if parts[-1] == parts[-2] || (parts.length > 1 && parts[-1].blank?)
              parts.join("/").underscore
            end
          end

          # The module that holds the per-message event classes for the service.
          # @return [Module]
          def event_message_namespace
            @event_message_namespace ||=
              begin
                namespace = name.deconstantize
                return unless namespace.present?

                namespace = namespace.constantize
                domain    = name.demodulize.sub("Service", "").singularize

                # Must use exceptions instead of const_defined? so that rails has
                # a change to autoload the constant.
                begin
                  namespace.const_get("#{domain}Events")
                rescue NameError
                  namespace.const_get("Events")
                end
              end
          end
        end
    end
  end
end
