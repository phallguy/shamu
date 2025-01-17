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
      attr_reader :principal_id

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
      attr_reader :principal_id_chain

      #
      # @!endgroup Attributes

      def initialize(principal_id: nil, super_principal: nil, remote_ip: nil, elevated: false, scopes: nil)
        @principal_id = principal_id
        @super_principal = super_principal
        @remote_ip       = remote_ip
        @elevated        = elevated
        @scopes          = scopes && Array(scopes).sort.freeze
        @principal_id_chain =
          begin
            principal_ids = []
            principal = self
            while principal
              principal_ids << principal.principal_id if principal.principal_id.present?
              principal = principal.super_principal
            end

            principal_ids.reverse.freeze
          end
      end

      # @return [Boolean] true if the [#principal_id] is being impersonated.
      def impersonated?
        !!super_principal
      end

      # Create a new impersonation {Principal}, cloning relevant principal to the
      # new instance.
      #
      # @param [Object] principal_id of the user to impersonate.
      # @return [Principal] the new principal.
      def impersonate(principal_id)
        self.class.new(principal_id: principal_id, super_principal: self, remote_ip: remote_ip, elevated: elevated)
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
        !principal_id
      end

      def inspect
        result = "<#{self.class.name}:0x#{object_id.to_s(16)}"
        inspectable_attributes.map do |name|
          value = send(name)
          result << " #{name}=#{send(name).inspect}" if value
        end
        result << ">"
        result
      end

      def pretty_print(pp)
        attributes = inspectable_attributes
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

      def inspectable_attributes
        %i[principal_id scopes elevated remote_ip super_principal]
      end

      def to_h
        result = { principal_id: principal_id }

        result[:remote_ip] = remote_ip if remote_ip.present?
        result[:elevated]  = true if elevated
        result[:scopes]    = scopes if scopes.present?
        result[:super]     = super_principal.to_h if super_principal
        result
      end
    end
  end
end
