module Shamu
  module Entities
    class ListScope

      # Include paging parsing and attributes. Adds the following attributes
      # to the list scope:
      #
      # ```
      # class UsersListScope < Shamu::Entities::ListScope
      #   include Shamu::Entities::ListScope::Paging
      # end
      #
      # scope = UsersListScope.coerce!( params )
      # scope.page      # => 1
      # scope.per_page # => 25
      # ```
      module Paging

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute page
        # @return [Integer] the current page number. 1 based.

        # @!attribute per_page
        # @return [Integer] number of records per page.

        # @!attribute default_per_page
        # @return [Integer] default number of records per page if not provided.

        #
        # @!endgroup Attributes

        def self.included( base )
          super

          base.attribute :page, coerce: :to_i
          base.attribute :per_page, coerce: :to_i, default: -> { default_per_page }
          base.attribute :default_per_page, coerce: :to_i, serialize: false
        end

        # @return [Boolean] true if the scope is paged.
        def paged?
          !!page || !!per_page
        end

      end
    end
  end
end
