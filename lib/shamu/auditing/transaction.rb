module Shamu
  module Auditing

    # An audit record of a discrete change transaction.
    class Transaction < Services::Request
      include Entities::EntityPath

      STANDARD_FILTER_KEYS = [
          :password,
          :password_confirmation,
          /token$/,
          :code
      ].freeze

      # ============================================================================
      # @!group Attributes
      #
      #

      # @!attribute
      # @return [Security::Principal] the principal authorized to perform the
      # {#action}.
      attribute :principal


      # @!attribute
      # @return [String] the primitive action that was requested, such as `add`,
      #     `remove`, or `change`.
      attribute :action, presence: true, coerce: :to_s

      # @!attribute
      # @return [Hash] the params payload and additional context values that
      # describes the change request to be performed by the {#action}.
      attribute :params

        def filtered_params
          filter_params( params )
        end

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

      # Filter out keys in the {#params} has with the given key name or regular
      # expression. Values of matching keys will not be logged.b
      #
      # @param [Symbol, Regexp] key
      def filter( *key )
        @filter_keys = @filter_keys.dup if filter_keys == STANDARD_FILTER_KEYS
        @filter_keys.concat key
      end


      private

        attr_reader :entities

        def assign_params_to_model( model )
          if params.present?
            model.params_json =
              if defined? Oj
                Oj.dump( filtered_params, mode: :rails )
              else
                filtered_params.to_json
              end
          end

          if principal.present?
            model.user_id_chain = principal.user_id_chain
            model.ip_address = principal.remote_ip if model.respond_to?( :ip_address= )
          end
        end

        def filter_params( params )
          return unless params

          params.each_with_object({}) do |(key, value), filtered|
            filtered[ key ] =
              if filter_key?( key )
                "FILTERED"
              else
                value
              end
          end
        end

        def filter_key?( key )
          filter_keys.any? { |f| f === key }
        end

        def filter_keys
          @filter_keys ||= STANDARD_FILTER_KEYS
        end

    end
  end
end
