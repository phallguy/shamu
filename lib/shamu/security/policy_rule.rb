module Shamu
  module Security

    # A rule capturing the permitted actions and resources for {Policy}
    # permissions.
    class PolicyRule

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Object] the value to return as the result of a {Policy#permit?}
      #     call if the rule matches the request.
        attr_reader :result

      #
      # @!endgroup Attributes

      def initialize( actions, resource, result, block )
        @actions  = actions
        @resource = resource
        @result   = result
        @block    = block
      end

      # Determines if the rule matches the request action permission on the
      # given resource.
      #
      # @param [Symbol] action to be performed.
      # @param [Object] resource the action will be performed on.
      # @param [Object] additional context offered to {Policy#permit?}.
      #
      # @return [Boolean] true if the rule is a match.
      def match?( action, resource, additional_context )
        return true  if actions.include? :any
        return false unless actions.include? action
        return false unless resource_match?( resource )

        if block && !resource.is_a?( Module )
          block.call( resource, additional_context )
        else
          true
        end
      end

      private

        attr_reader :actions
        attr_reader :resource
        attr_reader :block

        def resource_match?( candidate )
          return true if resource == candidate
          return true if resource.is_a?( Module ) && candidate.is_a?( resource )

          # Allow 'doubles' to match in specs
          true if defined?( RSpec::Mocks::Double ) && candidate.is_a?( RSpec::Mocks::Double )
        end

    end
  end
end
