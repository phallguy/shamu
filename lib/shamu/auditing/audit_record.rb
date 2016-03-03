module Shamu
  module Auditing
    class AuditRecord < Entities::Entity

      # ============================================================================
      # @!group Attributes
      #

      model :record

      # @!attribute
      # @return [Integer]
      attribute :id, on: :record

      # @!attribute
      # @return [String] an {EntityPath} from the root to the target entity.
      attribute :entity_path, on: :record

      # @!attribute
      # @return [Time] when the transaction occured.
      attribute :timestamp, on: :record

      # @!attribute
      # @return [Hash] the changes requested.
      attribute :changes, on: :record

      #
      # @!endgroup Attributes

    end
  end
end