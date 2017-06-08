module Shamu
  module Security

    # Used in specs and service to service delegated requests to effectively
    # offer no policy and permit all actions.
    class NoPolicy < Policy

      # (see Policy#permit?)
      def permit?( * )
        :yes
      end

    end
  end
end
