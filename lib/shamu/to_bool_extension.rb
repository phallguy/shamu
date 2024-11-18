module Shamu
  # Adds `to_bool` to strings, numbers, booleans and nil class to provide a
  # consistent means of parsing values to a Boolean type.
  module ToBoolExtension
    # Extend common classes to add `to_model_id` method.
    def self.extend!
      String.include(Strings)
      Integer.include(Integers)
      TrueClass.include(Boolean)
      FalseClass.include(Boolean)
      NilClass.include(Nil)
    end

    # Add `to_model_id` to String types.
    module Strings
      def to_bool(default = false)
        case self
        when "1", /\At(rue)?\z/i, /\Ay(es)?\z/i     then true
        when "0", "", /\Af(alse)?\z/i, /\An(o)?\z/i then false
        else                                             default
        end
      end
    end

    # Add `to_model_id` to Integer types.
    module Integers
      def to_bool(default = false)
        case self
        when 1 then true
        when 0 then false
        else        default
        end
      end
    end

    # Add `to_model_id` to Boolean types.
    module Boolean
      def to_bool(_default = self)
        self
      end
    end

    # Add `to_model_id` to nil.
    module Nil
      def to_bool(default = self)
        default
      end
    end
  end
end

Shamu::ToBoolExtension.extend!