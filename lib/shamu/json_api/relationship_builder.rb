require "shamu/json_api/base_builder"

module Shamu
  module JsonApi

    # Build a relationship from one resource to another.
    class RelationshipBuilder < BaseBuilder

      # (see Context#include_resource)
      def include_resource( resource, serializer = nil, &block )
        context.include_resource resource, serializer, &block
      end

    end
  end
end