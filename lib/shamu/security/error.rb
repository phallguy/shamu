require "i18n"

module Shamu
  module Security
    # A generic error class for problems with shamu services.
    class Error < Shamu::Error
      private

        def translation_scope
          super.dup.insert(1, :security)
        end
    end

    # The requested action was not permitted on the resource.
    class AccessDeniedError < Error
      # ============================================================================
      # @!group Attributes
      #

      # @return [Symbol] the requested action that was denied.
      attr_reader :action

      # @return [Object] the resource the {#action} was to be performed on.
      attr_reader :resource

      # @return [Principal] the security {Principal} in use at the time of the
      #     policy violation.
      attr_reader :principal

      # @return [Object] additional principal provided to the policy authorization
      #     method.
      attr_reader :additional_context

      #
      # @!endgroup Attributes

      def initialize(_message = :access_denied, action: nil, resource: nil, principal: nil, additional_context: nil)
        @action             = action
        @resource           = resource
        @principal          = principal
        @additional_context = additional_context

        super(translate(:access_denied, action: action, resource: resource))
      end
    end

    # Security has been included but has not been completely set up.
    class IncompleteSetupError < Error
      def initialize(message = :incomplete_setup)
        super
      end
    end

    # A policy check was performed on an ActiveRecord resource
    class NoActiveRecordPolicyChecksError < Error
      def initialize(message = :no_actiev_record_policy_checks)
        super
      end
    end

    # Principal does not support impersonation.
    class NoPolicyImpersonationError < Error
      def initialize(message = :no_policy_impersonation)
        super
      end
    end
  end
end
