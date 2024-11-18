module Shamu
  module Events
    module ActiveRecord
      # The model used to store the event messages in the database.
      class Message < ::ActiveRecord::Base
        self.table_name = "shamu_event_messages"
        self.primary_key = "id"

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute
        # @return [String] id of the message a UUID.

        # @!attribute
        # @return [Integer] channel_id

        # @!attribute
        # @return [String] message the serialized message.

        # @!attribute
        # @return [DateTime] timestamp when the event was submitted.

        #
        # @!endgroup Attributes

        # ============================================================================
        # @!group Scope
        #

        # @!attribute
        # @return [ActiveRecord::Relation] messages posted to the given channel.
        scope :by_channel, lambda { |name|
          where(channel: name)
        }

        # @!attribute
        # @return [ActiveRecord::Relation] messages posted after the given created_at.
        scope :since, lambda { |created_at|
          where(arel_table[:created_at].gt(created_at))
        }

        #
        # @!endgroup Scope
      end
    end
  end
end