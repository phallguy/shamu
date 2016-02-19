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

      private

        # @!visibility public
        #
        # Publish the given `message` to the {#events_service}.
        #
        # @param [Events::Message] message the custom event specific message to
        #     publish.
        # @param [String] channel to publish to.
        # @return [void]
        def event!( message, channel: event_channel )
          events_service.publish channel, message
        end

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
            base_name = self.class.name || "Events"
            parts     = base_name.split( "::" )
            parts[-1].sub!( /Service$/, "" )
            parts.pop if parts[-1] == parts[-2] || ( parts.length > 1 && parts[-1].blank? )
            parts.join( "/" ).underscore
          end
        end

    end
  end
end