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

      STANDARD_FILTER_KEYS = [
          :password,
          :password_confirmation,
          :access_token,
          :auth_token,
          :token
      ].freeze

      def self.create( scorpion, *args )
        scorpion.fetch Shamu::Auditing::NullAuditingService, *args
      end

      # Records an auditable event in persistent storage.
      # @param [Transaction] transaction
      # @return [Result] indicates if logging was successful
      def commit( transaction )
        fail NotImplementedError
      end

      # @!return [Array<Symbol>] the list of keys that should be filtered in
      # the logged changes.
      def filter_keys
        STANDARD_FILTER_KEYS
      end

      private

        def filter_changes( changes )
          filter_keys.each_with_object( changes.dup ) do |key, filtered|
            filtered[ key ] = "FILTERED" if filter_key?( key )
          end
        end

        def filter_key?( key )
          filter_keys.include?( key.to_sym )
        end

    end
  end
end
