module Shamu
  module Security

    # Adds support for authorizing and querying security {Policy} to a
    # {Services::Service}.
    module Support
      extend ActiveSupport::Concern

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute security_principal
      # @return [Security::Principal] the principal offered to the service for
      #     policy resolution.

      # @!attribute roles_service
      # @return [Security::RolesService] a roles service to retrieve the roles
      #     granted to the {#security_principal}.

      #
      # @!endgroup Dependencies

      included do
        attr_dependency :security_principal, Security::Principal unless method_defined? :security_principal
        attr_dependency :roles_service, Security::RolesService unless method_defined? :roles_service
      end

      # @return [Policy] the security {Policy} for the service.
      def policy
        @policy ||= _policy_class.new(
          principal: security_principal,
          roles: roles_service.roles_for( security_principal )
        )
      end

      # @!method authorize!( action, resource, additional_context = nil )
      # @see Security::Policy#authorize!
      # @return [resource]

      # @!method permit?( action, resource, additional_context = nil )
      # @see Policy#permit?
      # @return [:yes, :maybe, false]

      delegate :authorize!, :permit?, to: :policy

      private

        def _policy_class
          if service_policy_delegation?
            delegate_policy_class
          else
            policy_class
          end
        end

        # @!visibility public
        #
        # Override to declare the policy class to use for the service.
        #
        # @return [Class] a {Policy} class used to authorize actions.
        def policy_class
          fail Security::IncompleteSetupError, "No policy class defined. Override #policy_class in #{ self.class.name } to declare policy." # rubocop:disable Metrics/LineLength
        end

        # @!visibility public
        #
        # @return [Class] a {Policy} class used when
        #     {#service_policy_delegation?}  is true.
        def delegate_policy_class
          NoPolicy
        end

        # @!visibility public
        #
        # @return [Boolean] true if the service has been asked to delegate
        #     policy checks to the upstream service and
        def service_policy_delegation?
        end

    end
  end
end