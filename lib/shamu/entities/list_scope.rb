module Shamu
  module Entities

    # The desired scope of entities offered {Services::Service} to prepare a
    # list of {Entity entities}.
    #
    # ### Standard scopes
    #
    # - {Paging}
    # - {ScopedPaging}
    # - {Dates}
    # - {Sorting}
    #
    # @example
    #   class UsersListScope < Shamu::Entities::ListScope
    #
    #     # Include standard paging options (page, per_page) from ListScopes::Paging
    #     include Shamu::Entities::ListScope::Paging
    #
    #     # Allow client to request that users be limited to those in one of the
    #     # given roles.
    #     attribute :roles, array: true, coerce: :to_s
    #   end
    class ListScope
      include Attributes
      include Attributes::Assignment
      include Attributes::Validation

      require "shamu/entities/list_scope/paging"
      require "shamu/entities/list_scope/scoped_paging"
      require "shamu/entities/list_scope/window_paging"
      require "shamu/entities/list_scope/dates"
      require "shamu/entities/list_scope/sorting"


      # Clone the params but exclude the given parameters.
      # @param [Array<Symbol>] param_names to exclude.
      # @return [ListScope]
      def except( *param_names )
        self.class.new( to_attributes( except: param_names ) )
      end

      # @return [Hash] the hash of attributes that can be used to generate a url.
      def params
        params = to_attributes
        params.each do |key, value|
          params[key] = value.params if value.respond_to?( :params )
        end
        params
      end

      class << self
        # Coerces a hash or params object to a proper ListScope object.
        # @param [Object] params to be coerced.
        # @return [ListScope] the coerced scope
        def coerce( params )
          if params.is_a?( self )
            params
          elsif params.respond_to?( :to_h ) || params.respond_to?( :to_attributes )
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

        # Finds the natural {ListScope} class for the given entity class.
        #
        # Users::UserEntity -> Users::UserListScope or Users::ListScope
        #
        # @param [Class] entity_class the {Entity} class to find a scope for.
        # @return [ListScope] the custom list scope if found, otherwise
        #     {ListScope}.
        def for( entity_class )
          base_name = entity_class.name || "Entity"
          name = base_name.sub /(Entity)?$/, "ListScope"
          begin
            return name.constantize

            # Rescuing instead of using const_defined? so that active record can
            # do it's auto-loading magic.
          rescue NameError # rubocop:disable Lint/HandleExceptions
          end

          name = base_name.sub /::[A-Za-z0-9]+(Entity)?$/, "::ListScope"

          begin
            return name.constantize
          rescue NameError # rubocop:disable Lint/HandleExceptions
          end

          self
        end
      end
    end
  end
end
