module Shamu
  module Security

    # ...
    class Principal

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Object] id of the currently authenticated user. May be cached,
      #     for example bu via persistent cookie. See {#elevated}.
        attr_reader :user_id

      # @!attribute
      # @return [Principal] the parent principal when a user or service is
      #     impersonating another user.
        attr_reader :parent_principal

      # @!attribute
      # @return [String] the IP address of the remote user.
        attr_reader :remote_ip

      # @!attribute
      # @return [Boolean] true if the user has elevated this session by
      #     providing their credentials.
        attr_reader :elevated
        alias_method :elevated?, :elevated

      #
      # @!endgroup Attributes

      def initialize( user_id: nil, parent_principal: nil, remote_ip: nil, elevated: false )
        @user_id          = user_id
        @parent_principal = parent_principal
        @remote_ip        = remote_ip
        @elevated         = elevated
      end

      # @return [Array<Object>] all of the user ids in the security principal
      #  chain, starting from the root.
      def user_id_chain
        @user_ids ||= begin
          user_ids = []
          principal = self
          while principal
            user_ids << principal.user_id
            principal = principal.parent_principal
          end

          user_ids.reverse
        end
      end

      # @return [Boolean] true if the [#user_id] is being impersonated.
      def impersonated?
        !!parent_principal
      end

      # Create a new impersonation {Principal}, cloning relevant principal to the
      # new instance.
      #
      # @param [Object] user_id of the user to impersonate.
      # @return [Principal] the new principal.
      def impersonate( user_id )
        self.class.new( user_id: user_id, parent_principal: self, remote_ip: remote_ip, elevated: elevated )
      end

    end
  end
end