module Shamu
  module Auditing
    # Writes audit logs to the {Shamu::Logger}.
    class LoggingAuditingService < AuditingService
      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [Shamu::Logger]
      attr_dependency :logger, Shamu::Logger

      #
      # @!endgroup Dependencies

      # Records an auditable event in persistent storage.
      # @param [Transaction] transaction
      # @return [AuditRecord] the persisted record.
      def commit(transaction)
        logger.unknown("AUDIT TRANSACTION action: #{transaction.action} entity: #{transaction.entity_path} by user: #{transaction.principal.try(:user_id_chain)} params: #{transaction.filtered_params}")
      end
    end
  end
end
