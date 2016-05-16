module Shamu
  module Security

    # ...
    class DelegatePrincipal < Principal

      # (see Principal#impersonate)
      def impersonate( user_id )
        fail NoPolicyImpersonationError
      end

      # (see Principal#service_delegate?)
      def service_delegate?
        true
      end

    end
  end
end