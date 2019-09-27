module Shamu
  module JsonApi
    module BuilderMethods
      module Link
        # Write a link  to another resource.
        #
        # @param [String,Symbol] name of the link.
        # @param [String] url
        # @param [Hash] meta optional additional meta information.
        # @return [self]
        def link( name, url, meta: nil )
          return if context.linkage_only?

          links = ( output[:links] ||= {} )

          if meta # rubocop:disable Style/ConditionalAssignment
            links[ name.to_sym ] = { href: url, meta: meta }
          else
            links[ name.to_sym ] = url
          end

          self
        end
      end
    end
  end
end