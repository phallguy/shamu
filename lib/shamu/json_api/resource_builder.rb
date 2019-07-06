require "shamu/json_api/base_builder"

module Shamu
  module JsonApi

    # Used by a {Serilaizer} to write fields and relationships
    class ResourceBuilder < BaseBuilder

      include BuilderMethods::Identifier

      # @overload attribute( attributes )
      #   @param [Hash] attributes to write.
      # @overload attribute( name, value )
      #   @param [String, Symbol] name of the attribute.
      #   @param [Object] value that can be persited to a JSON primitive value.
      #
      # Write one or more attributes to the output.
      #
      # @return [void]
      def attribute( name_or_hash, value = nil )
        require_identifier!

        if name_or_hash.is_a?(Hash)
          name_or_hash.each do |n, v|
            add_attribute n, v
          end
        else
          add_attribute name_or_hash, value
        end
      end
      alias_method :attributes, :attribute

      # Build a relationship reference.
      #
      # ```
      # relationship :author do |builder|
      #   builder.identifier author
      #   builder.link :related, author_url author
      #   builder.link :self, book_author_url( book, author )
      # end
      # ```
      #
      # @param [String,Symbol] name of the relationship.
      # @return [void]
      # @yield (builder)
      # @yieldparam [RelationshipBuilder] builder used to define the properties
      #     of the relationship.
      def relationship( name, &block )
        require_identifier!

        include_or_mark_partial name do
          builder = RelationshipBuilder.new( context )
          yield builder

          relationships = ( output[:relationships] ||= {} )
          relationships[ name.to_sym ] = builder.compile
        end
      end

      private

        def add_attribute( name, value )
          include_or_mark_partial name do
            attributes = ( output[:attributes] ||= {} )
            attributes[ name.to_sym ] = value
          end
        end

        def include_or_mark_partial(field)
          if context.include_field?( type, field )
            yield
          else
            meta :partial, true
          end
        end
    end
  end
end