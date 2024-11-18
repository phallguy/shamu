module Shamu
  module Events
    module ActiveRecord
      # Registry of event channels.
      class Channel < ::ActiveRecord::Base
        self.table_name = "shamu_event_channels"

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute
        # @return [String] name of the channel.

        #
        # @!endgroup Attributes

        # ============================================================================
        # @!group Scope
        #

        # @!attribute
        # @return [ActiveRecord::Relation] messages posted to the given channel.
        scope :by_name, lambda { |name|
          where(name: name)
        }

        #
        # @!endgroup Scope
      end
    end
  end
end