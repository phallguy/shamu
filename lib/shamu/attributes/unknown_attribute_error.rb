module Shamu
  module Attributes
    class UnknownAttributeError < Error
      def initialize( message = :unknown_attribute_named, attribute:, attribute_class: )
        super translate( message, attribute: attribute, attribute_class: attribute_class)
      end

      private

      def translation_scope
        super.dup.insert( 1, :attributes )
      end
    end
  end
end
