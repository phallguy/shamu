module Shamu
  module Security

    # Used to determine the roles that the current {Principal} should be given
    # on a {Services::Service}.
    module RolesService

      # @!visibility private
      def self.create( scorpion, * )
        scorpion.new EmptyRolesService
      end

      # @param [Principal] principal of the currently logged in user.
      # @return [Array<Symbol>] the roles granted to the principal.
      def roles_for( principal )
        []
      end

      # Default {RolesService} always returns an empty set.
      class EmptyRolesService
        include RolesService

        # (see RolesService#roles_for)
        def roles_for( principal )
          []
        end
      end
    end
  end
end