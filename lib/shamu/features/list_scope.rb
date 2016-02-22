module Shamu
  module Features

    # Select the features to be listed.
    class ListScope < Entities::ListScope

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Symbol] the desired type of toggle.
      attribute :type, inclusion: { in: Features::Toggle::TYPES }

      # @!attribute
      # @return [Symbol] only include toggles that have retired but are still
      #     configured.
      attribute :retired, coerce: :to_bool

      # @!attribute
      # @return [String] include toggles with a name that is prefixed with the
      #     given value.
      attribute :prefix, coerce: :to_s

      #
      # @!endgroup Attributes

    end
  end
end
