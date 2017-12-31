module Shamu
  module Entities
    class ListScope

      # Include sorting parameters and parsing.
      #
      # ```
      # class UsersListScope < Shamu::Entities::ListScope
      #   include Shamu::Entities::ListScope::Sorting
      # end
      #
      # scope = UserListScope.coerce!( sort_by: { first_name: :desc } )
      # scope.sort_by   #=> { first_name: :desc }
      #
      # scope = UserListScope.coerce!( sort_by: :first_name )
      # scope.sort_by   #=> { first_name: :asc }
      #
      # scope = UserListScope.coerce!( sort_by: [ :first_name, :last_name ] )
      # scope.sort_by   #=> { first_name: :asc, last_name: :asc }
      # ```
      module Sorting

        # ============================================================================
        # @!group Attributes
        #

        # @!attribute sort_by
        # @return [Hash] the attributes and directions to sort by.
        #
        # The sort attribute is coerced by converting arrays to a hash with a
        # default direction of :asc for each attribute.
        #
        # ```
        # scope.sort_by :name                   # => { name: :asc }
        # scope.sort_by :name, :created_at      # => { name: :asc, created_at: :asc }
        # scope.sort_by :count, rating: :desc   # => { count: :asc, rating: :desc }
        # ```

        #
        # @!endgroup Attributes

        def self.included( base )
          super

          base.attribute :default_sort_by, as: :default_order,
                                           coerce: ->( *values ) { parse_sort_by( values ) }

          base.attribute :sort_by, as: :order,
                                   coerce: ->( *values ) { parse_sort_by( values ) },
                                   default: -> { default_sort_by }
        end

        # @return [Boolean] true if the scope is paged.
        def sorted?
          !!sort_by
        end

        # @return [Hash] gets a normalized hash of attribute to direction with
        # all transforms applied.
        def sort_by_resolved
          return sort_by unless reverse_sort?

          sort_by.each_with_object( {} ) do |( attribute, direction ), resolved|
            resolved[ attribute ] = direction == :asc ? :desc : :asc
          end
        end

        private

          def reverse_sort?
            @reverse_sort
          end

          def reverse_sort!
            @reverse_sort = true
            self.sort_by = { id: :asc } unless sort_by_set?
          end

          def parse_sort_by( arguments )
            Array( arguments ).each_with_object( {} ) do |arg, sorted|
              case arg
              when Array          then sorted.merge!( parse_sort_by( arg ) )
              when Hash           then
                arg.each do |attr, direction|
                  case direction
                  when :asc, :desc, "asc", "desc" then sorted[attr] = direction.to_sym
                  when Array, Hash                then sorted[attr] = parse_sort_by( direction )
                  else                                 fail ArgumentError
                  end
                end
              when String, Symbol then sorted[arg.to_sym] = :asc
              else                     fail ArgumentError
              end
            end
          end

      end
    end
  end
end
