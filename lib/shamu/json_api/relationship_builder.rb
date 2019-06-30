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
      # @return [self]
      def identifier( type, id = :not_set )
        output[:data] ||= {}
        add_identifier( output[:data], type, id )

        self
      end

      # Writes relationship linkage for each of the related resources.
      #
      # @param [Enumerable] resources the collection of resources to reference.
      # @return [self]
      def collection( resources, &block )
        identifier_satisfied!

        output[:data] = resources.map do |resource|
          builder = CollectionBuilder.new(context)
          yield resource, builder

          builder.compile
        end

        self
      end

      # Explicitly indicate that there is a single related resource and it has
      # not yet been set.
      #
      # @return [self]
      def missing_one
        identifier_satisfied!
        output[:data] = nil
        self
      end

      # Explicitly indicate that there is a collection of related resources but
      # the collection is currently empty.
      #
      # @return [self]
      def missing_many
        identifier_satisfied!
        output[:data] = []
        self
      end

      def link(name, *args)
        identifier_satisfied! if name == :self
        super
      end

    end
  end
end