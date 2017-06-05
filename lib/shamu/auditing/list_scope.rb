module Shamu
  module Auditing
    class ListScope < Entities::ListScope

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [String] entity_path
      attribute :entity_path

      # @!attribute
      # @return [Object] user_id
      attribute :user_id

      #
      # @!endgroup Attributes

    end
  end
end
