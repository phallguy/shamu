require "multi_json"

module Shamu
  module Events

    # The {EventsService} handles receiving messages ({#publish}) and
    # dispatching them to all registered subscribers ({#subscriber}). The actual
    # delivery and message transport is defined by the concrete implementations
    # of the {EventService}. See "Included Event Systems" below.
    #
    # Use `.` or `/` to namespace and group channels. Channels are not related
    # to each other but namespacing can help organize and group channels in
    # reports and back-end tools.
    #
    # > Events are not guaranteed to be delivered and may be delivered more than
    # > once. Event processing should be idempotent and resilient to message
    # > loss.
    #
    # ## Included Event Systems
    #
    # - {InMemory In Memory} intended for decoupling services all running
    #   withing the same process. This is the default.
    # - {ActiveRecord} for low volume high-latency communications in a smaller
    #   system.
    #
    # ## Selecting an Event System
    #
    # Shamu relies on {https://github.com/phallguy/scorpion Scorpion} to resolve
    # dependencies. To select which event system to use, prepare the scorpion
    # with specific hunting instructions.
    #
    # ```
    # Scorpion.prepare do
    #   capture Shamu::Events::ActiveRecord::Service
    # end
    # ```
    class EventsService < Services::Service

      # Prepare the default event service implementation to use. The default
      # event service can be overridden when setting up the scorpion.
      #
      # @example
      #   Scorpion.prepare do
      #     capture Shamu::Events::EventsService do |scorpion, *args|
      #       scorpion.fetch Shamu::Events::InMemory::AsyncService, *args
      #     end
      #   end
      #
      # @return [EventsService]
      def self.create( scorpion, *args, &block )
        @events_service ||= scorpion.fetch InMemory::Service # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      # Publish a well-defined {Message} to a known channel so that any client
      # that has {#subscribe subscribed} will receive a copy of the message to
      # process.
      #
      # Events are delivered asynchronously. There is no guarantee that a
      # subscriber has received or processed a message.
      #
      # @param [String] channel to publish to.
      # @param [Message] message to publish.
      # @return [void]
      def publish( channel, message )
        fail NotImplementedError
      end

      # Subscribe to receive notifications of events on the named channel. Any
      # time a publisher pushes a message `callback` will be invoked with a copy
      # of the message.
      #
      # @param [String] channel to listen to.
      # @yield (message)
      # @yieldparam [Message] message
      # @return [void]
      def subscribe( channel, &callback )
        fail NotImplementedError
      end

      # Subscribe to the given channels from one service and forward them to
      # another service.
      #
      # @param [EventsService] from the service to subscribe to.
      # @param [EventsService] to the service to forward to.
      # @param [Array<String>] the channels to forwar.
      # @return [void]
      def self.bridge( from, to, *channels )
        Array( channels ).each do |channel|
          from.subscribe( channel ) do |message|
            to.publish channel, message
          end
        end
      end

      private

        # @!visibility public
        #
        # Serialize a message so that it can be transfered from publisher to
        # subsriber.
        #
        # @param [Message] message to serializer.
        # @return [String] the serialized message.
        def serialize( message )
          MultiJson.dump \
            class: message.class.name,
            attributes: message.to_attributes
        end

        # @!visibility public
        #
        # Deserialize a message back to a {Message} instance.
        #
        # @param [String] raw data.
        # @return [Message] the deserialized message.
        def deserialize( raw )
          hash = MultiJson.load( raw )
          message_class = hash["class"].constantize
          scorpion.fetch message_class, hash["attributes"]
        end

        def fetch_channel( name )
          channels[name] || begin
            mutex.synchronize do
              channels[ name ] ||= create_channel( name )
            end
          end
        end

        def create_channel( name )
          fail NotImplementedError, "Implement `def create_channel( name )` in #{ self.class.name }"
        end

    end
  end
end
