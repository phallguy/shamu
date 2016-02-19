require "shamu/security/roles"

module Shamu
  module Security

    # ...
    #
    # @example
    #   class UserPolicy < Shamu::Security::Policy
    #
    #     role :admin, inherits: :manager
    #     role :manager
    #     role :user
    #
    #     private
    #
    #       def permissions
    #         alias_action :email, to: :contact
    #
    #         permit :contact, UserEntity if in_role?( :manager )
    #         permit :email, UserEntity do |user|
    #           user.public_profile?
    #         end
    #       end
    #   end
    #
    #   principal = Shamu::Security::Principal.new( user_id: user.id )
    #   policy = UserPolicy.new(
    #     principal: principal,
    #     roles: roles_service.roles_for( principal )
    #     )
    #
    #   if policy.permit? :contact, user
    #     mail_to user
    #   end
    class Policy
      include Security::Roles

      # ============================================================================
      # @!group Dependencies
      #

      # @!attribute
      # @return [Principal] principal holding user identity and access credentials.
        attr_reader :principal

      # @!attribute
      # @return [Array<Roles>] roles that have been granted to the {#principal}.
        attr_reader :roles
      #
      # @!endgroup Dependencies

      def initialize( principal: nil, roles: nil )
        @principal = principal || Principal.new
        @roles     = roles || []
      end


      # Authorize the given `action` on the given resource. If it is not
      # {#permit? permitted} then an exception is raised.
      #
      # @param (see #permit?)
      # @return [resource]
      # @raise [AccessDeniedError] if not permitted.
      def authorize!( action, resource, additional_context = nil )
        return resource if permit?( action, resource, additional_context ) == :yes

        fail Security::AccessDeniedError,
             action: action,
             resource: resource,
             additional_context: additional_context,
             principal: principal
      end

      # Determines if the given `action` may be performed on the given
      # `resource`.
      #
      # @param [Symbol] action to perform.
      # @param [Object] resource the resource the action will be performed on.
      # @param [Object] additional_context that the policy may consider.
      # @return [:yes, :maybe, false] a truthy value if permitted, otherwise
      #     false. The truthy value depends on the certainty of the policy. A
      #     value of `:yes` or `true` indicates the action is always permitted.
      #     A value of `:maybe` indicates the action is permitted but the user
      #     may need to present additional credentials such as logging on this
      #     session or entering a TFA code.
      def permit?( action, resource, additional_context = nil )
        fail_on_active_record_check( resource )

        rules.each do |rule|
          next unless rule.match?( action, resource, additional_context )

          return rule.result
        end

        false
      end

      private

        # The rules that have been defined.
        def rules
          @rules ||= begin
            @rules = []
            permissions
            @rules
          end
        end

        # Mapping of action names to aliases.
        def aliases
          @aliases ||= {}
        end

        # @!visibility public
        #
        # @param [Array<Symbol>] roles to check.
        # @return [Boolean] true if the {#principal} has been granted one of the
        #     given roles.
        def in_role?( *roles )
          ( principal_roles & roles ).any?
        end

        def principal_roles
          @principal_roles ||= begin
            expanded = self.class.expand_roles( *roles )
            expanded << :user if principal.user_id && self.class.role_defined?( :user )
            expanded
          end
        end

        # ============================================================================
        # @!group DSL
        #

        # @!visibility public
        #
        # Hook to be overridden by a derived class to define the set of rules
        # that {#permit?} should consider when evaluating the {#principal}'s
        # permissions on a resource.
        #
        # Rules defined in the permissions block are evaluated in reverse order
        # such that the last matching {#permit} or {#deny} will determine the
        # permission.
        #
        # If no rules match, the permission is denied.
        #
        # @example
        #   def permissions
        #     permit :read, UserEntity
        #
        #     deny :read, UserEntity do |user|
        #       user.protected_account? && !in_role( :admin )
        #     end
        #   end
        #
        # @return [void]
        def permissions
          fail IncompleteSetupError, "Permissions have not been defined. Add a private `permissions` method to #{ self.class.name }" # rubocop:disable Metrics/LineLength
        end

        # @!visibility public
        #
        # Permit one or more `actions` to be performed on a given `resource`.
        #
        # When a block is provided the policy will yield to the block to allow
        # for more complex or context aware policy checks. The block is not
        # called if the resource offered to {#permit?} is a Class or Module.
        #
        # @example
        #   permit :read, UserEntity
        #   permit :show, :dashboard
        #   permit :update, UserEntity do |user|
        #     user.id == principal.user_id
        #   end
        #   permit :destroy, UserEntity do |user, additional_context|
        #     in_role?( :admin ) && additional_context[:custom_data] == :safe
        #   end
        #
        # @param [Array<Symbol>] actions to be permitted.
        # @param [Object] resource to perform the action on or the Class of
        #     instances to permit the action on.
        # @yield ( resource, additional_context )
        # @yieldparam [Object] resource instance or Class offered to {#permit?}
        #     that the requested action is to be performed on.
        # @yieldparam [Object] additional_context offered to {#permit?}.
        # @yieldreturn [:yes, :maybe, false] see {#permit?}.
        # @return [void]
        def permit( *actions, resource, &block )
          result = @when_elevated ? :maybe : :yes

          add_rule( actions, resource, result, &block )
        end

        # @!visibility public
        #
        # Explicitly deny an action previously granted with {#permit}.
        #
        # @param (see #permit)
        # @return [void]
        # @yield (see #permit)
        # @yieldparam (see #permit)
        # @yieldreturn [Boolean] true to deny the action.
        def deny( *actions, resource, &block )
          add_rule( actions, resource, false, &block )
        end

        # @!visibility public
        #
        # Only {#authorize!} the permissions defined in the given block when the
        # {#principal} has elevated this session by providing their credentials.
        #
        # Permissions defined in the block will yield a `:maybe` result when
        # queried via {#permit?} and will raise an {AccessDeniedError} when
        # an {#authorize!} check is enforced.
        #
        # This allows you to enable/disable UX in response to what a user should
        # be capable of doing but wait to actually allow it until they have
        # offered their credentials.
        #
        # @return [void]
        def when_elevated( &block )
          current = @when_elevated
          @when_elevated = true
          yield
          @when_elevated = current
        end

        # @!visibility public
        #
        # Add an action alias so that granting the alias will result in permits
        # for any of the listed actions.
        #
        # @example
        #  alias_action :show, :list, to: :read
        #  permit :read, :stuff
        #
        #  permit?( :show, :stuff )  # => :yes
        #  permit?( :list, :stuff )  # => :yes
        #  permit?( :read, :stuff )  # => :yes
        #  permit?( :write, :stuff ) # => false
        #
        # @param [Array<Symbol>] actions to alias.
        # @param [Symbol] to the action that should permit all the listed aliases.
        # @return [void]
        def alias_action( *actions, to: fail ) # bug in rubocop chokes on trailing required keyword
          aliases[to] ||= []
          aliases[to] |= actions
        end

        #
        # @!endgroup DSL

        def add_rule( actions, resource, result, &block )
          rules.unshift PolicyRule.new( expand_aliases( actions ), resource, result, block )
        end

        def expand_aliases( actions )
          expanded = actions.dup
          actions.each do |action|
            expand_alias_into( action, expanded )
          end

          expanded
        end

        def expand_alias_into( candidate, expanded )
          return unless mapped = aliases[candidate]

          mapped.each do |action|
            next if expanded.include? action

            expanded << action
            expand_alias_into( action, expanded )
          end
        end

        def fail_on_active_record_check( resource )
          return unless resource
          return unless defined? ActiveRecord

          if resource.is_a?( ActiveRecord::Base ) || ( resource.is_a?( Class ) && resource < ActiveRecord::Base )
            fail NoActiveRecordPolicyChecksError
          end
        end

    end
  end
end