module Shamu
  module Entities
    class ListScope
      # Limit/offset style paging using first/after naming conventions typical
      # in GraphQL implementations.
      #
      # ```
      # class UsersListScope < Shamu::Entities::ListScope
      #   include Shamu::Entities::ListScope::WindowPaging
      # end
      #
      # scope = UsersListScope.coerce!( params )
      # scope.first    # => 25
      # scope.after    # => 75
      # ```
      module WindowPaging
        # ============================================================================
        # @!group Attributes
        #

        # @!attribute first
        # @return [Integer] get the first n records.

        # @!attribute after
        # @return [Integer] the number of records to skip from the beginning.

        # @!attribute last
        # @return [Integer] get the last n records.

        # @!attribute before
        # @return [Integer] the number of records to skip from the end.

        #
        # @!endgroup Attributes

        def self.included(base)
          super

          base.attribute(:first, coerce: :to_i, default: -> { default_first })
          base.attribute(:default_first, coerce: :to_i, serialize: false)

          base.attribute(:after, coerce: :to_i)

          base.attribute(:last, default: -> { default_last }, coerce: lambda { |value|
            ensure_includes_sorting!
            reverse_sort!

            value.to_i if value
          })

          base.attribute(:default_last, serialize: false, coerce: lambda { |value|
            ensure_includes_sorting!
            reverse_sort!

            value.to_i if value
          })

          base.attribute(:before, coerce: lambda { |value|
            ensure_includes_sorting!
            reverse_sort!

            value.to_i if value
          })

          base.validate(:only_first_or_last)
        end

        # @return [Boolean] true if the scope is paged.
        def window_paged?
          first? || last?
        end

        private

          def first?
            !!first || !!after
          end

          def last?
            !!last || !!before
          end

          def only_first_or_last
            errors.add(:base, :only_first_or_last) if first? && last?
          end

          def ensure_includes_sorting!
            unless respond_to?(:reverse_sort!, true)
              raise "Must include Shamu::Entities::ListScope::Sorting to use last/before"
            end
          end
      end
    end
  end
end
