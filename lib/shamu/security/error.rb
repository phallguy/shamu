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

      def initialize(message = :access_denied, action: nil, resource: nil, principal: nil, additional_context: nil)
        @action             = action
        @resource           = resource
        @principal          = principal
        @additional_context = additional_context

        super(translate(message, action: action, resource: resource))
      end

      def inspect
        str = StringIO.new
        PP.pp(self, str)

        str.string
      end

      def pretty_inspect(pp)
        pretty_print(pp)
      end

      def pretty_print(pp)
        pp.object_address_group(self) do
          pp.seplist(%i[message resource action]) do |attr|
            pp.breakable(" ")
            pp.group(1) do
              pp.text(attr.to_s)
              pp.text(":")
              pp.breakable(" ")
              pp.pp(send(attr.name))
            end
          end
        end
      end
    end

    class CredentialsExpiredError < Error
      def initialize(message = :token_expired)
        super
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
