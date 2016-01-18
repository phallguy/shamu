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

      # DSL for declaring fluid assignment.
      module DSL

        private

          def define_attribute_reader( name )
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{ name }( *args )
                if args.length > 0
                  assign_#{ name }( *args )
                  self
                else
                  return @#{ name } if defined? @#{ name }
                  @#{ name } = fetch_#{ name }
                end
              end
            RUBY
          end

      end

    end
  end
end