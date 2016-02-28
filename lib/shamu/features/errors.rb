module Shamu
  module Features

    # An error occcured in the Features domain.
    class Error < Shamu::Error

      private

        def translation_scope
          super.dup.insert( 1, :features )
        end

    end

    # An feature toggle was checked that has been marked as retired.
    class RetiredToggleError < Error

      # @!attribute
      # @return [Toggle] the retired toggle
      attr_reader :toggle

      def initialize( toggle )
        @toggle = toggle

        super translate( :retired_toggle_checked, name: toggle.name, retire_at: toggle.retire_at.to_s )
      end
    end
  end
end