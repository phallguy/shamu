module Shamu
  module Events
    module ActiveRecord

      # Keep track of the last time message processed by a channel dispatch
      # runner.
      class Runner < ::ActiveRecord::Base

        self.table_name = "shamu_event_runners"
        self.primary_key = "id"

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute id
        # @return [String] the runner's UUID.

        # @!attribute last_processed_timestamp
        # @return [Datetime] timestamp of the last message processed.

        #
        # @!endgroup Attributes

      end
    end
  end
end