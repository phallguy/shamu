module Shamu
  module Entities

    # The desired scope of entities offered {Services::Service} to prepare a
    # list of {Entity entities}.
    #
    # @example
    #   class UsersListScope < Shamu::Entities::ListScope
    #
    #     # Include standard paging options (page, page_size) from ListScopes::Paging
    #     paging
    #
    #     # Allow client to request that users be limited to those in one of the
    #     # given roles.
    #     attribute :roles, array: true, coerce: :to_s
    #   end
    class ListScope
      include Attributes
      include Attributes::Assignment
      include Attributes::FluidAssignment
      include Attributes::Validation

      # @return [Hash] the scope as a hash of values that can be used to
      #     generate a url of the requested scope.
      def to_param
        to_attributes
      end

      # Clone the params but exclude the given parameters.
      # @param [Array<Symbol>] param_names to exclude.
      # @return [ListScope]
      def except( *param_names )
        self.class.new( to_attributes( except: param_names ) )
      end

      private

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

      class << self
        # Coerces a hash or params object to a proper ListScope object.
        # @param [Object] params to be coerced.
        # @return [ListScope] the coerced scope
        def coerce( params )
          if params.is_a?( self )
            params
          elsif params.respond_to?( :to_h )
            new( params )
          elsif params.nil?
            new
          else
            raise ArgumentError
          end
        end

        # Coerces the given params object and raises an ArgumentError if any of
        # the parameters are invalid.
        # @param (see .coerce)
        # @return (see .coerce)
        def coerce!( params )
          coerced = coerce( params )
          raise ArgumentError unless coerced.valid?
          coerced
        end

        # Include paging parsing and attributes. Adds the following attributes
        # to the list scope:
        #
        # - **page** (Integer) the current page number. 1 based.
        # - **page_size** (Integer) size of the page.
        # - **default_page_size** (Integer) page size to use if not provided.
        #
        # @param [Symbol] name of the page attribute. Default :page.
        # @param [Integer] page_size the default page size.
        # @return [void]
        #
        # @example
        #   class UsersListScope < Shamu::Entities::ListScope
        #     paging
        #   end
        #
        #   scope = UsersListScope.coerce!( params )
        #   scope.page      # => 1
        #   scope.page_size # => 25
        def paging( name: :page, page_size: 25 )
          attribute name, coerce: :to_i, default: 1
          attribute :"#{ name }_size", coerce: :to_i, default: ->() { send :"default_#{ name }_size" }
          attribute :"default_#{ name }_size", coerce: :to_i, default: page_size, serialize: false
        end

        # Include paging parsing and attributes exposed as a nested page object.
        # Adds the following attributes to the list scope:
        #
        # - **page.number** (Integer) the current page number. 1 based.
        # - **page.size** (Integer) size of the page.
        # - **page.default_size** (Integer) page size to use if not provided.
        #
        # @param [Symbol] name of the page attribute. Default :page.
        # @param [Integer] page_size the default page size.
        # @return [void]
        #
        # @example
        #   class UsersListScope < Shamu::Entities::ListScope
        #     scoped_paging
        #   end
        #
        #   scope = UsersListScope.coerce!( page: { number: 5, size: 50 } )
        #   scope.page.number # => 5
        #   scope.page.size   # => 50
        def scoped_paging( name: :page, page_size: 25 )
          klass = Class.new do
            include Shamu::Attributes

            attribute :number, coerce: :to_i, default: 1
            attribute :size, coerce: :to_i, default: ->() { default_size }
            attribute :default_size, coerce: :to_i, default: page_size, serialize: false
          end

          attribute name, build: klass, default: klass.new
        end

        # Include since and until attributes and parsing for date ranges.
        #
        # - **since** (Time) the earliest date in the range.
        # - **default_since** (Time) time to use if since is not provided.
        # - **until** (Time) the latest date in the range.
        # - **default_until** (Time) time to use if until is not provided.
        #
        # @return [void]
        #
        # @example
        #   class UsersListScope < Shamu::Entities::ListScope
        #     dates
        #   end
        #
        #   scope = UsersListScope.coerce!( since: 5.days.ago, until: 2.weeks.from_now )
        #   scope.since     # => Time...
        #   scope.until     # => Time...
        def dates
          coerce = Time.instance_method( :to_time ) ? :to_time : nil

          attribute :since, coerce: coerce, default: ->() { default_since }
          attribute :default_since, coerce: coerce, serialize: false
          attribute :until, coerce: coerce, default: ->() { default_until }
          attribute :default_until, coerce: coerce, serialize: false
        end

        # Include sorting parameters and parsing.
        #
        # @param [Symbol] name of the sorting attribute. Deafult :sort_by.
        # @return [void]
        #
        # @example
        #   class UsersListScope < Shamu::Entities::ListScope
        #     sorting
        #   end
        #
        #   scope = UserListScope.coerce!( sort_by: { first_name: :desc } )
        #   scope.sort_by   #=> { first_name: :desc }
        #
        #   scope = UserListScope.coerce!( sort_by: :first_name )
        #   scope.sort_by   #=> { first_name: :asc }
        #
        #   scope = UserListScope.coerce!( sort_by: [ :first_name, :last_name ] )
        #   scope.sort_by   #=> { first_name: :asc, last_name: :asc }
        #
        def sorting( name: :sort_by )
          attribute name, coerce: ->( *values ) { parse_sort_by( values ) }
        end

      end

    end
  end
end