module Shamu
  module Auditing

    # An audit record of a discrete change transaction.
    class Transaction < Services::Request
      include Entities::EntityPath

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Array<Object>] the chain of user ids making the request.
      attribute :user_id_chain, presence: true

      # @!attribute
      # @return [String] the primitive action that was requested, such as `add`,
      #     `remove`, or `change`.
      attribute :action, presence: true

      # @!attribute
      # @return [Hash] the changes by attribute requested in the transaction.
      attribute :changes

      # The {EntityPath} describing how to reach the leaf entity {#append_entity
      # appended} from the root entity.
      attribute :entity_path, presence: true do
        compose_entity_path( entities )
      end

      #
      # @!endgroup Attributes

      # Appends a child node to the {#entity_path}.
      # @overload append_entity( entity )
      #   @param [Entities::Entity] an entity
      # @overload append_entity( pair )
      #   @param [Array<String,Object>] pair consisting of entity class and id.
      def append_entity( entity )
        @entities ||= []
        entities << entity
      end

      # (see Services::Request#apply_to)
      def apply_to( model )
        super.tap do
          model.changes_json = changes.to_json if changes.present?
        end
      end

      private

        attr_reader :entities

    end
  end
end
