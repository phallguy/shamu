module Shamu
  module JsonApi
    module Rails

      # Pagination information gathered from the request.
      class Pagination
        include Attributes
        include Attributes::Assignment
        include Attributes::Validation

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute
        # @return [Symbol] the request parameter the pagination was read from. Default `:page`.
        attribute :param, default: :page

        # @!attribute
        # @return [Integer] the page number.
        attribute :number, coerce: :to_i

        # @!attribute
        # @return [Integer] the size of each page.
        attribute :size, coerce: :to_i

        # @!attribute
        # @return [Integer] offset into the list.
        attribute :offset, coerce: :to_i

        # @!attribute
        # @return [Integer] limit the total number of results.
        attribute :limit, coerce: :to_i

        # @!attribute
        # @return [String] opaque cursor value
        attribute :cursor, coerce: :to_s

        #
        # @!endgroup Attributes

        validate :only_one_kind_of_paging

        private

          def only_one_kind_of_paging
            kinds = [ number, offset, cursor ].compact
            errors.add :base, :only_one_kind_of_paging if kinds.count > 2 || ( size && limit )
          end

      end
    end
  end
end