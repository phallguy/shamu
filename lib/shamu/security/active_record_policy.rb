module Shamu
  module Security

    # Extends the standard {Policy} class to add {ActiveRecord::Relation}
    # refinements based on granted policies.
    #
    # @example
    #   class UserPolicy < Shamu::Security::ActiveRecordPolicy
    #     private
    #
    #       def permissions
    #         permit :read, UserEntity do |user|
    #           user.public?
    #         end
    #
    #         refine :read, Models::User do |users, additional_context|
    #           users.where( public: true )
    #         end
    #       end
    #
    #   end
    #
    #   class UsersService < Shamu::Services::Service
    #     include Shamu::Security::Support
    #
    #     def list
    #       entity_list policy.refine_relation( :list, Model::User.all ) do |record|
    #         scorpion.fetch UserEntity, record: record
    #       end
    #     end
    #
    #     private
    #
    #       def policy_class
    #         UserPolicy
    #       end
    #   end
    class ActiveRecordPolicy < Policy

      # Refine an {ActiveRecord::Relation} to select only those records
      # permitted for the given `action`.
      #
      # @param [Symbol] action to perform on the {Entities::Entity} that will be
      #     projected from the records.
      # @param [ActiveRecord::Relation] relation to refine.
      # @param [Object] additional_context that the {#refine} block may consider
      #     when applying the refinement.
      # @return [ActiveRecord::Relation] the refined relation.
      def refine_relation( action, relation, additional_context = nil )
        resolve_permissions
        refined = false

        if refinements.blank?
          fail IncompleteSetupError, "Refinements have not been defined. Add refinements in the permission definitions of #{ self.class.name }" # rubocop:disable Metrics/LineLength
        end

        refinements.each do |refinement|
          if refinement.match?( action, relation, additional_context )
            refined  = true
            relation = refinement.apply( relation, additional_context ) || relation
          end
        end

        refined ? relation : relation.none
      end

      private

        # ============================================================================
        # @!group Dependencies
        #

        # @!visibility public
        #
        # Declare a refinement that should be applied to an
        # {ActiveRecord::Relation} for the given actions. {#refine_relation}
        # will yield the relation to any matching refinement to reduce the scope
        # of available records available for projection.
        #
        # @example
        #   def permissions
        #     permit :read, UserEntity do |user|
        #       user.public?
        #     end
        #     refine :read, Models::User do |users, additional_context|
        #       users.where( public: true )
        #     end
        #   end
        #
        # @param [Array<Symbol>] actions that should be refined.
        # @param [Class] model_class the {ActiveRecord::Base} class to refine.
        # @yield (relation, additional_context)
        # @yieldparam [ActiveRecord::Relation] relation to refine.
        # @yieldparam [Object] additional_context offered to {#refine_relation}.
        # @yieldreturn [ActiveRecord::Relation,nil] the refined relation, or nil
        #     if no refinement should be applied.
        # @return [void]
        def refine( *actions, model_class, &block )
          fail "No actions defined" if actions.blank?
          refinements << PolicyRefinement.new( expand_aliases( actions ), model_class, block )
        end

        #
        # @!endgroup Dependencies

        def refinements
          @refinements ||= []
        end

    end
  end
end
