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
      module Dates

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute since
        # @return [Time] include only records added since the given timestamp.

        # @!attribute until
        # @return [Time] include only records up until the given timestamp.

        # @!attribute default_since
        # @return [Time] default {#since} if not specified.

        # @!attribute default_until
        # @return [Time] default {#until} if not specified.

        #
        # @!endgroup Attributes

        def self.included( base )
          super

          coerce = Time.instance_method( :to_time ) ? :to_time : nil

          base.attribute :since, coerce: coerce, default: -> { default_since }
          base.attribute :default_since, coerce: coerce, serialize: false
          base.attribute :until, coerce: coerce, default: -> { default_until }
          base.attribute :default_until, coerce: coerce, serialize: false
        end

        # @return [Boolean] true if the scope is dated.
        def dated?
          !!self.since || !!self.until # rubocop:disable Style/RedundantSelf
        end

      end
    end
  end
end