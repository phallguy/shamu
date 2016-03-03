module Shamu
  module Services

    # Lazily look up an associated resource
    class LazyAssociation < Delegator

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Object] the primary key id of the association. Not delegated so
      #     it is safe to use and will not trigger an unnecessary fetch.
      attr_reader :id

      #
      # @!endgroup Attributes

      def initialize( id, &block )
        @id = id
        @block = block
      end

      def __getobj__
        return @association if defined? @association

        @association = @block.call
      end
    end
  end
end