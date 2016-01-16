module Shamu

  # Provide  attributes that project data from another source (such as an
  # external API, ActiveRecord model, cached data, etc.) providing simple
  # transformations.
  #
  # @example
  #
  #   class Person
  #     include Shamu::Attributes
  #
  #     attribute :name
  #   end
  module Attributes
    require 'shamu/attributes/assignment'
    require 'shamu/attributes/fluid_assignment'

    def self.included( base )
      base.extend( Attributes::DSL )
      super
    end

    def initialize( **attributes )
      assign_attributes( attributes )
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
        self.class.attributes.each do |key,options|
          if attributes.has_key?( key )
            value = attributes[ key ]
          elsif options.has_key?( :default )
            value = options[ :default ]
          else
            next
          end

          send :"assign_#{ key }", value
        end
      end

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
      # @param [Symbol] name of the attribute
      # @param [Symbol] on another method on the class to delegate the attribute
      #     to.
      # @param [Object] default value if not set.
      # @return [void]
      def attribute( name, **args, &block )
        attributes[name.to_sym] = args

        define_attribute_reader( name )
        define_attribute_assignment( name, **args )

        if args.has_key?( :on )
          define_delegate_fetcher( name, args[:on] )
        else
          define_virtual_fetcher( name, &block )
        end

        private :"fetch_#{ name }"
        private :"assign_#{ name }"
      end

      private

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

        def define_delegate_fetcher( name, on )
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def fetch_#{ name }
              #{ on } && #{ on }.#{ name }
            end
          RUBY
        end

        def define_attribute_assignment( name, **args )
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def assign_#{ name }( value )
              @#{ name } = value
            end
          RUBY
        end

    end

  end
end