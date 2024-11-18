module Shamu
  module Events
    # Indicates that an {EventsService} supports reporting channel activity states.
    module ChannelStats
      # Gets stats for the given `channel`.
      #
      # #### Stats Included in the results.
      #
      # - **name** name of the channel.
      # - **subscribers_count** the number of subscribers.
      # - **queue_size** the size of the message queue.
      # - **dispatching** true if the channel is currently dispatching messages.
      #
      # @param [String] name  of the channel
      # @return [Hash] stats.
      def channel_stats(name)
        raise(NotImplementedError)
      end
    end
  end
end