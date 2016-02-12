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
      extend ActiveSupport::Concern

      included do |base|
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
        raise "Must include Shamu::Attributes::Assignment first." unless base < Shamu::Attributes::Assignment
      end

      # DSL for declaring fluid assignment.
      class_methods do

        private

          def define_attribute_reader( name, ** )
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