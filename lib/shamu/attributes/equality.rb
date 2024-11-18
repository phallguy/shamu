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
      def ==(other)
        return true if other.object_id == object_id
        return false unless other.is_a?(self.class) || is_a?(other.class)

        attributes_eql?(other)
      end
      alias eql? ==

      # @return [Integer] a hash computed from the attributes of the object.
      def hash
        self.class.attributes.map do |key, _|
          attribute_equality_value(send(key))
        end.hash
      end

      private

        # @return [Boolean] true if the object's attributes and `other`
        #     attributes are all `eql?` to each other.
        def attributes_eql?(other)
          self.class.attributes.all? do |key, attr|
            next true if attr[:ignore_equality]

            attribute_eql?(other, key)
          end
        end

        # @param [Object] other the other object.
        # @param [Symbol] attr the name of the other attribute.
        # @return [Boolean] true if the value of the given attribute is equal
        # on the current object and the other object.
        def attribute_eql?(other, attr)
          value       = attribute_equality_value(send(attr))
          other_value = attribute_equality_value(other.send(attr))

          value.eql?(other_value)
        end

        def attribute_equality_value(value)
          # When round-tripping to the database time often looses millisecond
          # precision so always normalize to seconds.
          if time_like_value?(value)
            value.to_time.to_i
          else
            value
          end
        end

        def time_like_value?(value)
          case value
          when Time, DateTime, ActiveSupport::TimeWithZone then true
          end
        end
    end
  end
end
