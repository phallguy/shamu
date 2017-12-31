require "thwait"

module Shamu
  module Events
    module InMemory

      # An asynchronous version of {Service}. Event subscribers should be able
      # to handle events coming in on a separate thread.
      class AsyncService < InMemory::Service

        def initialize
          ObjectSpace.define_finalizer self do
            threads = mutex.synchronize do
              channels.map do |_, state|
                state[:queue].close
                state[:thread]
              end
            end

            ThreadsWait.all_waits( *threads )
          end

          super
        end

        # (see Service#dispatch)
        def dispatch
          # No-op since messages are immediately dispatched on background threads.
        end

        private

          def create_channel( _ )
            state = super
            state[:thread] = channel_thread( state )
            state[:queue]  = Queue.new
            state
          end

          def channel_thread( state )
            Thread.new do
              dispatch_channel( state )
            end
          end

      end
    end
  end
end
