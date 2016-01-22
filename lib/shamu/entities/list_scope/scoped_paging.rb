module Shamu
  module Entities
    class ListScope

      # Include paging parsing and attributes exposed as a nested page object.
      # Adds the following attributes to the list scope:
      #
      # ```
      # class UsersListScope < Shamu::Entities::ListScope
      #   include Shamu::Entities::ListScope::ScopedPaging
      # end
      #
      # scope = UsersListScope.coerce!( page: { number: 5, size: 50 } )
      # scope.page.number # => 5
      # scope.page.size   # => 50
      # ```
      module ScopedPaging

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute page
        # @return [PageScope] the paging scope.

        #
        # @!endgroup Attributes

        def self.included( base )
          super

          base.attribute :page, build: PageScope, default: PageScope.new
        end

        # @return [Boolean] true if the scope is paged.
        def scoped_page?
          !!page.number
        end

        # The scope of a [ScopedPaging] list scope.
        class PageScope
          include Shamu::Attributes

          # @!attribute
          # @return [Integer] the page number.
          attribute :number, coerce: :to_i

          # @!attribute
          # @return [Integer] the size of each page.
          attribute :size, coerce: :to_i, default: ->() { default_size }

          # @!attribute
          # @return [Integer] the default page size if not specified.
          attribute :default_size, coerce: :to_i, default: 25, serialize: false
        end

      end
    end
  end
end