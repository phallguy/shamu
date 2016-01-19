module Shamu

  # Provide  attributes that project data from another source (such as an
  # external API, ActiveRecord model, cached data, etc.) providing simple
  # transformations.
  #
  # To add additional attribute functionality see
  #
  # - {Attributes::Assignment}
  # - {Attributes::FluidAssignment}
  # - {Attributes::Validation}
  #
  # @example
  #
  #   class Person
  #     include Shamu::Attributes
  #
  #     attribute :name
  #   end
  module Attributes
    require "shamu/attributes/assignment"
    require "shamu/attributes/fluid_assignment"
    require "shamu/attributes/validation"

    def self.included( base )
      base.extend( Attributes::DSL )
      super
    end

    def initialize( *attributes )
      assign_attributes( attributes.last )
    end

    private

      # @!visibility public
      #
      # Assign a hash of values to the matching instance variables.
      #
      # @param [Hash] attributes to assign.
      #
      # @return [self]
      def assign_attributes( attributes )
        attributes = resolve_attributes( attributes )

        self.class.attributes.each do |key, options|
          if attributes.key?( key )
            value = attributes[ key ]
          elsif options.key?( :default )
            value = options[ :default ]
          else
            next
          end

          if build = options[:build]
            value = build_value( build, value )
          end

          send :"assign_#{ key }", value
        end
      end

      def build_value( build, value )
        if build.is_a?( Class )
          klass = build
          build = ->(v) { klass.new( v ) }
        end

        build.call( value )
      end

      def resolve_attributes( attributes )
        if attributes.respond_to?( :to_attributes )
          attributes.to_attributes
        elsif attributes.respond_to?( :to_h )
          attributes.to_h
        else
          attributes
        end
      end

    # A DSL for declargin attributes for a class.
    module DSL

      # @return [Hash] of attributes and their options defined on the class.
      def attributes
        @attributes ||= {}
      end

      def inherited( subclass )
        # Clone the base class's attributes into the subclass
        subclass.instance_variable_set :@attributes, attributes.dup
        super
      end

      # Define a new attribute for the class.
      #
      # @overload attribute(name, on:, default:, build: )
      # @overload attribute(name, build, on:, default:)
      #
      # @param [Symbol] name of the attribute
      # @param [Symbol] on another method on the class to delegate the attribute
      #     to.
      # @param [Object] default value if not set.
      # @param [Class,#call] build method used to build a nested object on
      #     assignement of a hash with nested keys.
      # @return [self]
      def attribute( name, *args, **options, &block )
        name    = name.to_sym
        options = create_attribute( name, *args, **options )

        define_attribute_reader( name )
        define_attribute_assignment( name, **options )

        if options.key?( :on )
          define_delegate_fetcher( name, options[:on], options[:build] )
        else
          define_virtual_fetcher( name, &block )
        end

        private :"fetch_#{ name }"
        private :"assign_#{ name }"

        self
      end

      private

        # @return [Array<Symbol>] keys used by the {.attribute} method options
        #   argument. Used by {Attributes::Validation} to filter option keys.
        def attribute_option_keys
          [ :on, :build, :default ]
        end

        def create_attribute( name, *args, **options )
          options = options.dup
          options[:build] = args[0] if args.length > 0
          attributes[name] = options
        end

        def define_attribute_reader( name )
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{ name }
              return @#{ name } if defined? @#{ name }
              @#{ name } = fetch_#{ name }
            end
          RUBY
        end

        def define_virtual_fetcher( name, &block )
          if block_given?
            define_method :"fetch_#{ name }", &block
          else
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def fetch_#{ name }
                @#{ name }
              end
            RUBY
          end
        end

        def define_delegate_fetcher( name, on, builder )
          if builder
            define_method :"build_#{ name }" do |value|
              build_value( builder, value )
            end
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def fetch_#{ name }
                #{ on } && build_#{ name }( #{ on }.#{ name } )
              end
            RUBY
          else
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def fetch_#{ name }
                #{ on } && #{ on }.#{ name }
              end
            RUBY
          end
        end

        def define_attribute_assignment( name, ** )
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def assign_#{ name }( value )
              @#{ name } = value
            end
          RUBY
        end

    end

  end
end