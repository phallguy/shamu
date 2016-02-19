module Shamu
  module Security

    # Defines how an {ActiveRecord::Relation} is refined for an
    # {ActiveRecordPolicy}.
    class PolicyRefinement

      def initialize( actions, model_class, block )
        @actions     = actions
        @model_class = model_class
        @block       = block
      end

      # Determines if the refinement matches the request action permission on
      # the given relation.
      #
      # @param [Symbol] action to be performed on entities projected from the
      #     `relation`.
      # @param [ActiveRecord::Relation] relation to refine.
      # @param [Object] additional context offered to {Policy#permit?}.
      #
      # @return [Boolean] true if the rule is a match.
      def match?( action, relation, additional_context )
        return false unless actions.include? action
        return false unless model_class_match?( relation )

        true
      end

      # Apply the refinement to the relation.
      #
      # @param [ActiveRecord::Relation] relation to refine
      # @return [ActiveRecord::Relation]
      def apply( relation, additional_context )
        ( block && block.call( relation, additional_context ) ) || relation
      end

      private

        attr_reader :actions
        attr_reader :model_class
        attr_reader :block

        def model_class_match?( candidate )
          model_class <= candidate.klass
        end

    end
  end
end