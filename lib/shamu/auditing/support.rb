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

        private

          # Override {Shamu::Services::RequestSupport#with_partial_request} and to yield
          # a {Transaction} as an additional argument to automatically
          # {#audit_request audit the request}.
          def with_partial_request( *args, &block )
            super( *args ) do |request|
              audit_request request do |transaction|
                yield request, transaction
              end
            end
          end

      end

      private


        # @!visibility public
        #
        # Audit the requested changes and report the request to the
        # {#auditing_service}.
        #
        # @param [Services::Request] request the coerced request params.
        # @return (see Shamu::Services::RequestSupport#with_request)
        # @yield (transaction)
        # @yieldparam [Transaction] transaction the audit transaction. Most fields
        #     will be populated automatically from the request but the block
        #     should call {Transaction#append_entity} to include any parent
        #     entities in the entity path.
        # @yieldreturn [Services::Result]
        def audit_request( request, action: :smart, &block ) # rubocop:disable Metrics/PerceivedComplexity
          transaction = Transaction.new \
            user_id_chain: auditing_security_principal.user_id_chain,
            changes: request.to_attributes( only: request.assigned_attributes ),
            action: audit_request_action( request, action )

          result = yield transaction if block_given?
          result = Services::Result.coerce( result, request: request )

          if result.valid?
            if result.entity
              transaction.append_entity result.entity
            elsif !transaction.entities? && request.respond_to?( :id ) && defined? entity_class
              transaction.append_entity [ entity_class, request.id ]
            end
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
