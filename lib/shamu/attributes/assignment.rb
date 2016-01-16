module Shamu
  module Attributes
    module Assignment

      def self.included( base )
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
        base.extend( Assignment::DSL )
        super
      end

      module DSL

        # Define a new attribute for the class.
        #
        # @param (see Projection::DSL#attribute)
        # @param [Symbol, #call] coerce name of a method on the assigned value
        #     to call, or a custom method that can parse values when assigning
        #     the attribute.
        # @param [Boolean] array true if the expected value should be an array.
        #
        #
        # @return [void]
        #
        # @example
        #
        #   class Params
        #     include Shamu::Attributes
        #     include Shamu::Attributes::Assignment
        #
        #     attribute :created_at, coerce: :to_datetime
        #     attribute :count, coerce: :to_i
        #     attribute :label, coerce: ->(value){ value.upcase.to_sym }
        #     attribute :tags, coerce: :to_s, array: true
        #   end
        def attribute( name, **args, &block )
          super
          define_attribute_assignment( name, **args )
          define_attribute_writer( name )
        end

        private

          def define_attribute_assignment( name, coerce: :smart, array: false, ** )
            super

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def assign_#{ name }( value )
                @#{ name } = coerce_#{ name }#{ array ? '_array' : '' }( value )
              end
            RUBY
            private :"assign_#{ name }"

            define_attribute_coercion( name, coerce )
            define_attribute_array( name ) if array
          end

          def define_attribute_array( name )
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def coerce_#{ name }_array( value )
                value && Array( value ).map do |v|
                  coerce_#{ name }( v )
                end
              end
            RUBY

            private :"coerce_#{ name }_array"
          end

          def define_attribute_coercion( name, coerce )
            if coerce == :smart
              coerce =
                case name
                when /_at$/, /_on$/ then :to_datetime
                when /_ids?$/       then :to_i
                end
            end

            if coerce.is_a? Symbol
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def coerce_#{ name }( value )
                  value.#{ coerce }
                end
              RUBY
            elsif coerce
              define_method :"coerce_#{ name }", coerce
            else
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def coerce_#{ name }( value )
                  value
                end
              RUBY
            end

            private :"coerce_#{ name }"
          end

          def define_attribute_writer( name )
            alias_method :"#{ name }=", :"assign_#{ name }"
            public :"#{ name }="
          end

      end

    end
  end
end