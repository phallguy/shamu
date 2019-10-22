module Shamu
  module Security

    # Additional context and resources to consider when resolving the roles
    # that a {Principal} should be granted.
    class Context

      def initialize
        @providers = Hash.new([])
      end

      # Overridden in the application specific context for a request to return
      # the ids for a given domain to scope policy and roles for a service.
      #
      # For example working with a Customer service might be scoped by a
      # specific set of Business entities that a user is a member of. This
      # allows the upstream service to declare which business the request
      # should be resolved with.
      def entity_ids(domain)
        @providers[domain].map do |block|
          block.call(domain)
        end.flatten.compact
      end

      # Register a hook that can be used to provide the list of entity ids for
      # the given domain.
      def provide(domain, &block)
        @providers[domain] << block
      end
    end
  end
end
