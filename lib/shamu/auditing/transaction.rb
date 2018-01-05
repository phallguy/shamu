module Shamu
  module Auditing

    # An audit record of a discrete change transaction.
    class Transaction < Services::Request
      include Entities::EntityPath

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Array<Object>] the chain of user ids from the
      # {Security::Principal} in place at the time of the request.
      attribute :user_id_chain, presence: true, array: true, coerce: :to_model_id

      # @!attribute
      # @return [String] the primitive action that was requested, such as `add`,
      #     `remove`, or `change`.
      attribute :action, presence: true, coerce: :to_s

      # @!attribute
      # @return [Hash] the params payload and additional context values that
      # describes the change request to be performed by the {#action}.
      attribute :params

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
          assign_params_to_model model
        end
      end

      # @return [Boolean] true if entities have been added to the transaction.
      def entities?
        entities.present?
      end


      private

        attr_reader :entities

        def assign_params_to_model( model )
          if params.present?
            model.params_json =
              if defined? Oj
                Oj.dump( params, mode: :rails )
              else
                params.to_json
              end
          end
        end

    end
  end
end
