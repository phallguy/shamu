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
            send( key ).eql?( other.send( key ) )
          end
        end

    end
  end
end
