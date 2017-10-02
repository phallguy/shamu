require "thread"
require "thwait"

module Shamu
  module Events
    module InMemory

      # Provides an in-memory {EventsService} that dispatches {Message messages}
      # to subscribers within the same process.
      #
      # Messages are volitale and will be lost if the process crashes.
      class Service < EventsService
        include ChannelStats

        def initialize
          @mutex    = Thread::Mutex.new
          @channels = {}

          super
        end

        # (see EventsService#publish)
        def publish( channel, message )
          state = fetch_channel( channel )
          queue = state[ :queue ]
          queue.push serialize( message )
        end

        # (see EventsService#subscribe)
        def subscribe( channel, &callback )
          subscribers = fetch_channel( channel )[ :subscribers ]
          mutex.synchronize do
            subscribers << callback
          end
        end

        # Dispatch all pending mssages in the given named channels.
        # @param [Array<String>] names of the channels to dispatch. Dispatches
        #     to all queues if empty.
        # @return [void]
        def dispatch( *names )
          names = channels.keys if names.empty?

          names.each do |name|
            dispatch_channel( fetch_channel( name ) )
          end
        end

        # (see ChannelStats#chanel_stats)
        def channel_stats( name )
          channel = fetch_channel( name )

          {
            name: name,
            subscribers_count: channel[ :subscribers ].count,
            queue_size: channel[ :queue ].size,
            dispatching: channel[ :dispatching ]
          }
        end

        private

          attr_reader :channels
          attr_reader :mutex

          def create_channel( _ )
            {
              queue: [],
              subscribers: [],
            }
          end

          def dispatch_channel( state )
            mutex.synchronize do
              return if state[:dispatching]
              state[ :dispatching ] = true
            end

            dispatch_messages( state )
          ensure
            mutex.synchronize do
              state[ :dispatching ] = false
            end
          end

          def dispatch_messages( state )
            while raw_message = state[:queue].shift
              message = deserialize( raw_message )
              state[ :subscribers ].each do |subscriber|
                subscriber.call( message )
              end
            end
          end

      end
    end
  end
end
