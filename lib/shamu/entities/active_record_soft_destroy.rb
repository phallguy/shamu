module Shamu
  module Entities
    # Add the ability to "soft-delete" a record. Marking it as deleted so it is
    # no longer present in the default scope but without actually removing the
    # record from the database.
    #
    # > **Note** You must add a column `destroyed_at` to the model.
    module ActiveRecordSoftDestroy
      extend ActiveSupport::Concern

      included do
        # ============================================================================
        # @!group Attributes
        #

        # @!attribute destroyed_at
        # @return [DateTime] when the record was destroyed.

        #
        # @!endgroup Attributes

        # ============================================================================
        # @!group Scopes
        #

        # Limit the records to those that have been soft destroyed.
        # @return [ActiveRecord::Relation]
        scope :destroyed, -> { unscope(where: :destroyed_at).where(arel_table[:destroyed_at].not_eq(nil)) }

        # Limit the records to those that have not been destroyed.
        # @return [ActiveRecord::Relation]
        scope :except_destroyed, -> { unscope(where: :destroyed_at).where(arel_table[:destroyed_at].eq(nil)) }

        # Include live and soft destroyed records.
        # @return [ActiveRecord::Relation]
        scope :including_destroyed, -> { unscope(where: :destroyed_at) }

        # Exclude destroyed records by default.
        default_scope { except_destroyed }

        # Apply list scoping that includes targeting `destroyed` state.
        def self.apply_destroyed_list_scope(criteria, scope)
          return criteria if scope.destroyed.nil?

          if scope.destroyed
            criteria.destroyed
          else
            criteria.except_destroyed
          end
        end

        #
        # @!endgroup Scopes
      end

      # Mark the record as deleted.
      # @overload destroy
      # @return [Boolean] true if the record was destroyed.
      def destroy(options = nil)
        if destroyed_at || (options && options[:obliterate])
          super()
        else
          update_attribute(:destroyed_at, Time.now.utc)
        end
      end

      # Really destroy the record.
      # @return [Boolean] true if the record was destroyed.
      def obliterate
        destroy(obliterate: true)
      end

      # Really destroy! the record.
      # @overload destroy!
      # @return [Boolean] true if the record was destroyed.
      def destroy!(options = nil)
        if destroyed_at || (options && options[:obliterate])
          super()
        else
          update_attribute(:destroyed_at, Time.now.utc)
        end
      end

      # Really destroy! the record.
      # @return [Boolean] true if the record was destroyed.
      def obliterate!
        destroy!(obliterate: true)
      end

      # Mark the record as no longer destroyed.
      # @return [Boolean] true if the record was restored.
      def undestroy
        update_attribute(:destroyed_at, nil)
      end

      # @return [Boolean] true if the record has been soft destroyed.
      def soft_destroyed?
        !!destroyed_at
      end
    end
  end
end
