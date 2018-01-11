require "active_support/concern"

module Shamu
  module Attributes

    # Provide a means for defining writable attributes.
    module Assignment
      extend ActiveSupport::Concern

      included do |base|
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
        public :assign_attributes
      end

      # @param [Symbol] name of the attribute to assign.
      # @param [Object] value to assign.
      def []=( name, value )
        send :"assign_#{ name }", value if attribute?( name )
      end

      # @return [Array<Symbol>] the attributes that have been assigned.
      def assigned_attributes
        @assigned_attributes.to_a || []
      end

      # @return [Array<Symbol>] the attributes that have not been assigned.
      def unassigned_attributes
        self.class.attributes.keys - assigned_attributes
      end

      # @return [Boolean] true if the attribute as explicitly been defined -
      # not just present/memoized.
      def assigned?( name )
        assigned_attributes.include?( name )
      end

      private

        def assigned_attribute!( name )
          @assigned_attributes ||= Set.new
          @assigned_attributes << name
        end


      class_methods do

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
        #     attribute :created_at, coerce: :to_time
        #     attribute :count, coerce: :to_i
        #     attribute :label, coerce: ->(value){ value.upcase.to_sym }
        #     attribute :tags, coerce: :to_s, array: true
        #   end
        def attribute( name, *args, **options, &block )
          super( name, *args, **options )
          define_attribute_assignment( name, **options )
          define_attribute_writer( name, **options )
        end

        private

          def attribute_option_keys
            super + [ :coerce, :array ]
          end

          def define_attribute_assignment( name, coerce: :smart, array: false, ** )
            super

            mod = Module.new do
              module_eval <<-RUBY, __FILE__, __LINE__ + 1
                private def assign_#{ name }( *values )
                  assigned_attribute!( :#{ name } )
                  super coerce_#{ name }#{ array ? '_array' : '' }( *values )
                end
              RUBY
            end


            define_attribute_coercion( mod, name, coerce )
            define_attribute_array( mod, name ) if array

            include mod
          end

          def define_attribute_array( mod, name )
            mod.module_eval <<-RUBY, __FILE__, __LINE__ + 1
              private def coerce_#{ name }_array( value )
                value && Array( value ).map do |v|
                  coerce_#{ name }( v )
                end
              end
            RUBY
          end

          def define_attribute_coercion( mod, name, coerce ) # rubocop:disable Metrics/PerceivedComplexity
            coerce = cource_method( name, coerce )

            if coerce.is_a?( Class )
              mod.send :define_method, :"coerce_#{ name }_value" do |value|
                coerce.new( value ) if value
              end
            elsif !coerce || coerce.is_a?( Symbol )
              mod.module_eval <<-RUBY, __FILE__, __LINE__ + 1
                def coerce_#{ name }_value( value )
                  value#{ coerce && ".#{ coerce }" }
                end
              RUBY
            elsif coerce
              mod.send :define_method, :"coerce_#{ name }_value", coerce
            end

            mod.send :private, :"coerce_#{ name }_value"

            mod.module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def coerce_#{ name }( value )
                clean_#{ name }_attribute( coerce_#{ name }_value( value ) )
              end
            RUBY
          end

          def cource_method( name, coerce )
            if coerce == :smart
              case name
              when /_at$/, /_on$/ then method(:coerce_time_like_value)
              when /(^|_)ids?$/   then :to_model_id
              end
            else
              coerce
            end
          end

          def coerce_time_like_value(value)
            case value
            when nil                                         then value
            when Time, DateTime, ActiveSupport::TimeWithZone then value.to_time
            when Numeric                                     then Time.at( value )
            else
              return value.to_time if value.respond_to?( :to_time )
              raise ArgumentError, "Cannot coerce time like value"
            end
          end

          def define_attribute_writer( name, as: nil, ** )
            alias_method :"#{ name }=", :"assign_#{ name }"
            public :"#{ name }="

            alias_method :"#{ as }=", :"#{ name }=" if as
          end

          def define_attribute_reader( name, as: nil, ** )
            super

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{ name }_assigned?                # def attribute_assigned?
                assigned?( :#{ name } )              #   assigned( :attribute )
              end                                    # end
            RUBY
          end

      end

    end
  end
end
