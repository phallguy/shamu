module Shamu
  module Entities

    # The desired scope of entities offered {Services::Service} to prepare a
    # list of {Entity entities}.
    class ListScope
      include Attributes
      include Attributes::Assignment
      include Attributes::FluidAssignment
      include Attributes::Validation

      # Coerces a hash or params object to a proper ListScope object.
      # @param [Object] params to be coerced.
      # @return [ListScope] the coerced scope
      def self.coerce( params )
        if params.is_a?( self )
          params
        elsif params.respond_to?( :to_h )
          new( params )
        elsif params.nil?
          new
        else
          raise ArgumentError
        end
      end

      # Coerces the given params object and raises an ArgumentError if any of
      # the parameters are invalid.
      # @param (see .coerce)
      # @return (see .coerce)
      def self.coerce!( params )
        coerced = coerce( params )
        raise ArgumentError unless coerced.valid?
        coerced
      end
    end
  end
end