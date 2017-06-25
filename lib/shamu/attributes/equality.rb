module Shamu
  module Attributes

    # Override equality methods to support shallow comparison of attribute
    # values for equality.
    #
    # Add `ignore_equality: true` to any {Attributes::DSL#attribute} that
    # shouldn't be included in equality comparisons.
    module Equality

      # @param [Attributes] other object to compare with.
      # @return [Boolean] true if the two objects are of the same type and
      #     attributes are all eql? to each other.
      def ==( other )
        return true if other.object_id == object_id
        return false unless other.is_a?( self.class ) || is_a?( other.class )
        attributes_eql?( other )
      end
      alias_method :eql?, :==

      # @return [Integer] a hash computed from the attributes of the object.
      def hash
        self.class.attributes.map do |key, _|
          send( key )
        end.hash
      end

      private

        # @return [Boolean] true if the object's attributes and `other`
        #     attributes are all `eql?` to each other.
        def attributes_eql?( other )
          self.class.attributes.all? do |key, attr|
            next true if attr[:ignore_equality]
            attribute_eql?( other, key )
          end
        end

        # @param [Object] other the other object.
        # @param [Symbol] attr the name of the other attribute.
        # @return [Boolean] true if the value of the given attribute is equal
        # on the current object and the other object.
        def attribute_eql?( other, attr )
          send( attr ).eql?( other.send( attr ) )
        end

    end
  end
end
