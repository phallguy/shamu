require "shamu/json_api/base_builder"

module Shamu
  module JsonApi

    # Build a relationship from one resource to another.
    class RelationshipBuilder < BaseBuilder


      # (see Context#include_resource)
      def include_resource( resource, presenter = nil, &block )
        context.include_resource resource, presenter, &block
      end

      include BuilderMethods::Identifier

      # Write a resource linkage info.
      #
      # @param [String] type of the resource.
      # @param [Object] id of the resource.
      # @return [void]
      def identifier( type, id = :not_set )
        output[:data] ||= {}
        add_identifier( output[:data], type, id )

        self
      end

      private

      def require_identifier!
        # Identifiers are not required for relationships
      end

    end
  end
end