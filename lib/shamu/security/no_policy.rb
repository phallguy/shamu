module Shamu
  module Security

    # Used in specs and service to service delegated requests to effectively
    # offer no policy and permit all actions.
    class NoPolicy < Policy

      # (see Policy#permit?)
      def permit?( * )
        :yes
      end

      def refine_relation( action, relation, additional_context = nil )
        relation
      end

    end
  end
end
