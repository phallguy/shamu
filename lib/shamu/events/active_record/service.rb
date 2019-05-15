module Shamu
  module Events
    module ActiveRecord

      # Store events in a database using ActiveRecord persistence layer.
      #
      # ## Runner IDS
      #
      # A globally unique id (may be UUID or a well- defined internal
      # convention that guarantees uniqueness.) The runner id is used by the
      # system to track which messages have been delivered to the subscribers
      # hosted by that runner process. This allows dispatching to resume should
      # the host or process die.
      class Service < EventsService
        include ChannelStats

        # Ensure that the tables are present in the database and have been
        # initialized.
        #
        # @return [void]
        def self.ensure_records!
          return if @ensure_records

          @ensure_records = true
          Migration.new.migrate( :up )
        end

        def initialize
          self.class.ensure_records!
          @channels ||= {}
          @mutex    ||= Mutex.new

          super
        end

        # (see EventsService#publish)
        def publish( channel, message )
          channel_id = fetch_channel( channel )[:id]
          Message.create! channel_id: channel_id, message: serialize( message )
        end

        # (see EventsService#subscribe)
        def subscribe( channel, &callback )
          state = fetch_channel( channel )
          mutex.synchronize do
            state[:subscribers] << callback
          end
        end

        # Dispatch queued messages up to the given `limit`. Once all the
        # messages are dispatched, the method returns. A long running process
        # might periodically call dispatch in a loop trapping SIGINT to
        # shutdown.
        #
        # @param [String] runner_id that identifies the host and process
        #     responding to events.
        # @param [Array<String>] names of the channels to dispatch. If empty,
        #     dispatches to all subscribed channels.
        # @param [Integer] limit the maximum number of messages to dispatch. If
        #     not given, defaults to 100.
        #
        # @return [Hash<String,Integer>] the number of messages actually
        #     dispatched on each channel.
        def dispatch( runner_id, *names, limit: nil )
          fail UnknownRunnerError unless runner_id.present?

          names = channels.keys unless channels.present?

          names.each_with_object( {} ) do |name, dispatched|
            state = fetch_channel( name )
            dispatched[name] = dispatch_channel( state, "#{ runner_id }::#{ name }", limit )
          end
        end

        # (see ChannelStats#channel_stats)
        # @param [String] runner_id if provided, only show stats for the given runner.
        def channel_stats( name, runner_id: nil )
          channel = fetch_channel( name )
          queue   = Message.where( channel_id: channel[:id] )

          if runner_id && ( runner = create_runner( runner_id ) )
            queue = queue.where( Message.arel_table[ :id ].gt( runner.last_processed_id ) ) if runner.last_processed_id
          end

          {
            name: name,
            subscribers_count: channel[:subscribers].size,
            dispatching: channel[:dispatching],
            queue_size: queue.count
          }
        end

        private

          attr_reader :channels
          attr_reader :mutex

          def create_channel( name )
            {
              id: create_named_channel( name ).id,
              subscribers: []
            }
          end

          def dispatch_channel( state, runner_id, limit )
            mutex.synchronize do
              return if state[:dispatching]

              state[ :dispatching ] = true
            end

            dispatch_messages( state, runner_id, limit )
          ensure
            mutex.synchronize do
              state[ :dispatching ] = false
            end
          end

          def dispatch_messages( state, runner_id, limit )
            last_message = nil
            count = 0

            pending_messages( state, runner_id, limit ).each do |record|
              last_message = record
              message      = deserialize( record.message )

              count += 1

              state[ :subscribers ].each do |subscriber|
                subscriber.call( message )
              end
            end

            bookmark_runner( runner_id, last_message )

            count
          end

          def bookmark_runner( runner_id, last_message )
            return unless last_message

            runner = create_runner( runner_id )
            runner.update_attributes last_processed_id: last_message.id, last_processed_at: Time.now.utc
          end

          def pending_messages( state, runner_id, limit )
            messages = Message.where( channel_id: state[:id] )
                              .limit( limit )
            runner   = create_runner( runner_id )

            if runner.last_processed_id
              messages = messages.where( Message.arel_table[:id].gt( runner.last_processed_id ) )
            end

            messages
          end

          def create_runner( runner_id )
            Runner.transaction( requires_new: true ) do
              Runner.first_or_create!( id: runner_id )
            end
          end

          def create_named_channel( name )
            Channel.transaction( requires_new: true ) do
              Channel.first_or_create!( name: name )
            end
          end

      end
    end
  end
end
