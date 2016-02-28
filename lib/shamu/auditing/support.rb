module Shamu
  module Auditing

    # Add auditing support to a {Services::Servie}.
    module Support
      extend ActiveSupport::Concern

      included do
        include Shamu::Services::RequestSupport

        # ============================================================================
        # @!group Dependencies
        #

        # @!attribute
        # @return [Shamu::Auditing::AuditingService] the service to report audit
        #     transactions to.
        attr_dependency :auditing_service, Shamu::Auditing::AuditingService

        #
        # @!endgroup Dependencies

      end

      private

        # @!visibility public
        #
        # Audit the requested changes and report the request to the
        # {#auditing_service}.
        #
        # See {Shamu::Services::RequestSupport#with_request}
        #
        # @param (see Shamu::Services::RequestSupport#with_request)
        # @return (see Shamu::Services::RequestSupport#with_request)
        # @yield (request, transaction)
        # @yieldparam [Services::Request] request coerced from `params`.
        # @yieldparam [Transaction] transaction the audit transaction. Most fields
        #     will be populated automatically from the request but the block
        #     should call {Transaction#append_entity} to include any parent
        #     entities in the entity path.
        def audit_request( params, request_class, action: :smart, &block )
          transaction = Transaction.new \
            user_id_chain: auditing_security_principal.user_id_chain

          result = with_request params, request_class do |request|
            transaction.action  = audit_request_action( request, action )
            transaction.changes = request.to_attributes

            yield request, transaction
          end

          if result.valid?
            transaction.append_entity result.entity if result.entity
            auditing_service.commit( transaction )
          end

          result
        end

        def auditing_security_principal
          return @auditing_security_principal if defined? @auditing_security_principal

          @auditing_security_principal = security_principal if defined? security_principal
          @auditing_security_principal ||= scorpion.fetch Security::Principal
        end

        def audit_request_action( request, type )
          return type unless type == :smart

          request.class.name.demodulize.sub( "Request", "" ).underscore
        end
    end
  end
end