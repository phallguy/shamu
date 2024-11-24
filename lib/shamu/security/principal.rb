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
      # @return [Principal] the super principal when a user or service is
      #     impersonating another user.
      attr_reader :super_principal

      # @!attribute
      # @return [String] the IP address of the remote user.
      attr_reader :remote_ip

      # @!attribute
      # @return [Boolean] true if the user has elevated this session by
      #     providing their credentials.
      attr_reader :elevated

      alias elevated? elevated

      # @!attribute
      # @return [Array<Symbol>] security scopes the principal may be used to
      # authenticate against. When empty, no limits are imposed.
      attr_reader :scopes

      # @return [Array<Object>] all of the user ids in the security principal
      #  chain, starting from the root.
      attr_reader :user_id_chain

      #
      # @!endgroup Attributes

      def initialize(user_id: nil, super_principal: nil, remote_ip: nil, elevated: false, scopes: nil)
        @user_id         = user_id
        @super_principal = super_principal
        @remote_ip       = remote_ip
        @elevated        = elevated
        @scopes          = scopes && scopes.freeze
        @user_id_chain =
          begin
            user_ids = []
            principal = self
            while principal
              user_ids << principal.user_id
              principal = principal.super_principal
            end

            user_ids.reverse.freeze
          end
      end

      # @return [Boolean] true if the [#user_id] is being impersonated.
      def impersonated?
        !!super_principal
      end

      # Create a new impersonation {Principal}, cloning relevant principal to the
      # new instance.
      #
      # @param [Object] user_id of the user to impersonate.
      # @return [Principal] the new principal.
      def impersonate(user_id)
        self.class.new(user_id: user_id, super_principal: self, remote_ip: remote_ip, elevated: elevated)
      end

      # @return [Boolean] true if the principal was offered by one service to
      #     another and requesting that the downstream service delegate security
      #     checks to the calling service.
      def service_delegate?; end

      # @param [Symbol] scope
      # @return [Boolean] true if the principal is scoped to authenticate the
      # user for the given scope.
      def scoped?(scope)
        scopes.nil? || scopes.include?(scope)
      end

      # @!attribute
      # @return [Boolean] true if there is no user associated with the
      # principal.
      def anonymous?
        !user_id
      end

      def inspect
        result = "<#{self.class.name}:0x#{object_id.to_s(16)}"
        %i[user_id scopes elevated remote_ip super_principal].map do |name|
          value = send(name)
          result << " #{name}=#{send(name).inspect}" if value
        end
        result << ">"
        result
      end

      def pretty_print(pp)
        attributes = %i[user_id scopes elevated remote_ip super_principal]
        attributes = attributes.reject! { |a| send(a).nil? }

        pp.object_address_group(self) do
          pretty_print_custom(pp)
          pp.seplist(attributes, -> { pp.text(",") }) do |name|
            value = send(name)

            pp.breakable(" ")
            pp.group(1) do
              pp.text(name.to_s)
              pp.text(":")
              pp.breakable(" ")
              pp.pp(value)
            end
          end
        end
      end

      def pretty_print_custom(pp); end

      def to_h
        result = { user_id: user_id }

        result[:remote_ip] = remote_ip if remote_ip.present?
        result[:elevated]  = true if elevated
        result[:scopes]    = scopes if scopes.present?
        result[:super]     = super_principal.to_h if super_principal
        result
      end
    end
  end
end
