module Shamu
  module Services

    # Helper methods useful for services that interact with {ActiveRecord::Base}
    # models.
    module ActiveRecord

      private

        # @!visibility public
        #
        # Watch for ActiveRecord::RecordNotFound errors and rethrow as a
        # {Shamu::NotFoundError}.
        def wrap_not_found( &block )
          yield
        rescue ::ActiveRecord::RecordNotFound
          raise Shamu::NotFoundError
        end

        # @!visibility public
        #
        # Wrap all the changes to any ActiveRecord resource in a transaction.
        # @param [Hash] options to pass to
        #     ActiveRecord::Transactions.transaction.
        # @yieldreturn [Result] the validation sources for the transaction. See
        #     {Service#with_result}.
        # @return [Result]
        def with_transaction( options = {}, &block )
          result = nil

          ::ActiveRecord::Base.transaction options do
            result = yield
            raise ::ActiveRecord::Rollback if result && !result.valid?
          end

          result
        end

        # @!visibility public
        #
        # Apply the filters specified in `list_scope` to the `relation`.
        #
        # @param [ActiveRecord::Relation] relation to filter.
        # @param [Entities::ListScope] list_scope to apply.
        # @return [ActiveRecord::Relation] the scoped relation.
        def scope_relation( relation, list_scope )
          return unless relation

          if relation.respond_to?( :by_list_scope )
            relation.by_list_scope( list_scope )
          else
            fail "Can't scope a #{ relation.klass }. Add `scope :by_list_scope, ->(list_scope) { ... }` or include Shamu::Entities::ActiveRecord." # rubocop:disable Metrics/LineLength
          end
        end

    end
  end
end