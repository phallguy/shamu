module Shamu
  module Attributes

    # Provide a means for defining writable attributes.
    module Assignment

      def self.included( base )
        base.include( Shamu::Attributes )
        base.extend( Assignment::DSL )
        super
      end

      # A DSL for defining writable attributes.
      module DSL

        # Define a new attribute for the class.
        #
        # @param (see Projection::DSL#attribute)
        # @param [Symbol, #call] coerce name of a method on the assigned value
        #     to call, or a custom method that can parse values when assigning
        #     the attribute.
        # @param [Boolean] array true if the expected value should be an array.
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
        def attribute( name, *args, **options, &block )
          super
          define_attribute_assignment( name, **options )
          define_attribute_writer( name )
        end

        private

          def attribute_option_keys
            super + [ :coerce, :array ]
          end

          def define_attribute_assignment( name, coerce: :smart, array: false, ** )
            super

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def assign_#{ name }( *values )
                @#{ name } = coerce_#{ name }#{ array ? '_array' : '' }( *values )
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
            coerce = cource_method( name, coerce )

            if !coerce || coerce.is_a?( Symbol )
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def coerce_#{ name }( value )
                  value#{ coerce && ".#{ coerce }" }
                end
              RUBY
            elsif coerce
              define_method :"coerce_#{ name }", coerce
            end

            private :"coerce_#{ name }"
          end

          def cource_method( name, coerce )
            if coerce == :smart
              case name
              when /_at$/, /_on$/ then :to_datetime
              when /_ids?$/       then :to_i
              end
            else
              coerce
            end
          end

          def define_attribute_writer( name )
            alias_method :"#{ name }=", :"assign_#{ name }"
            public :"#{ name }="
          end

      end

    end
  end
end