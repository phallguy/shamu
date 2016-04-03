module Shamu
  module JsonApi
    module BuilderMethods
      module Meta
        # Add a meta field.
        # @param [String,Symbol] name of the meta field.
        # @param [Object] vlaue that can be converted to a JSON primitive type.
        # @return [self]
        def meta( name, value )
          meta = ( output[:meta] ||= {} )
          meta[ name.to_sym ] = value

          self
        end
      end
    end
  end
end