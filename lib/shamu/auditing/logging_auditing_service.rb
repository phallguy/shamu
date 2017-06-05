module Shamu
  module Auditing

    # Writes audit logs to the {Shamu::Logger}.
    class LoggingAuditingService < Services::Service

      # (see AuditingService#commit)
      def commit( transaction )
        logger.unknown "AUDIT TRANSACTION action: #{ transaction.action } entity: #{ transaction.entity_path } by user: #{ transaction.user_id_chain } changes: #{ transaction.changes }" # rubocop:disable Metrics/LineLength
      end

    end
  end
end
