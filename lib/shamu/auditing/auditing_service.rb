module Shamu
  module Auditing

    # Records audit {Transaction transactions} to record change requests made to
    # a {Services::Service} that includes auditing {Support}.
    #
    # > **Security Note** the audit service does not enforce any security policies
    # > for reading or writing. It is expected that audit transactions should be
    # > recordable by any service and that reading those audits will be limited by
    # > some admin only accessible resource. To expose the audit records via a web
    # > interface, create a proxy AuditingService that has it's own
    # > {Security::Policy} but delegates the actual reading and writing.
    class AuditingService < Services::Service

      def self.create( scorpion, *args )
        if defined? ActiveRecord
          scorpion.fetch Shamu::Auditing::ActiveRecord::Service, *args
        else
          fail "No available auditing service available."
        end
      end

      # Records an auditable event in persistent storage.
      # @param [Transaction] transaction
      # @return [AuditRecord] the persisted record.
      def commit( transaction )
        fail NotImplementedError
      end

    end
  end
end
