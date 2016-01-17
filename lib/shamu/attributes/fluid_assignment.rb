module Shamu
  module Attributes

    # Add  methods to a class to make it easy to build out an object using fluid
    # assignment.
    #
    # @example
    #
    #   # Without fluid
    #   obj = AttributeObject.new
    #   obj.name = '...'
    #   obj.email = '...'
    #
    #   # With fluid
    #   obj = FluidObject.new
    #   obj.name( '...' )
    #      .email( '...' )
    module FluidAssignment

      def self.included( base )
        raise "Must include Shamu::Attributes::Assignment first." unless base < Shamu::Attributes::Assignment
        base.extend( FluidAssignment::DSL )
        super
      end

      module DSL

        # Define a new attribute for the class.
        #
        # @param [Symbol] name of the attribute
        # @param (see Projection::DSL#attribute)
        #
        # @return [void]
        def attribute( name, **, &block )
          super
        end

      end

    end
  end
end