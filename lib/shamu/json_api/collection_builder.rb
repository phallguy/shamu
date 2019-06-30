require "shamu/json_api/base_builder"

module Shamu
  module JsonApi

    # Build a collection on a relationship.
    class CollectionBuilder < BaseBuilder

      # (see Context#include_resource)
      def include_resource( resource, presenter = nil, &block )
        context.include_resource resource, presenter, &block
      end

      include BuilderMethods::Identifier
    end
  end
end
