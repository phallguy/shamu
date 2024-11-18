module Shamu
  module Auditing
    # No-op on audit logging requests.
    class NullAuditingService < Services::Service
      # (see AuditingService#commit)
      def commit(transaction); end
    end
  end
end
