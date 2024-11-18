module Shamu
  module Security
    # ...
    class DelegatePrincipal < Principal
      # (see Principal#impersonate)
      def impersonate(_user_id)
        raise(NoPolicyImpersonationError)
      end

      # (see Principal#service_delegate?)
      def service_delegate?
        true
      end
    end
  end
end