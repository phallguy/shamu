require "active_support/concern"

module Shamu
  # Provide  attributes that project data from another source (such as an
  # external API, ActiveRecord model, cached data, etc.) providing simple
  # transformations.
  #
  # To add additional attribute functionality see
  #
  # - {Attributes::Assignment}
  # - {Attributes::Validation}
  # - {Attributes::Equality}
  # - {Attributes::HtmlSanitation}
  #
  # @example
  #
  #   class Person
  #     include Shamu::Attributes
  #
  #     attribute :name
  #   end
  module Attributes
    extend ActiveSupport::Concern

    require "shamu/attributes/assignment"
    require "shamu/attributes/validation"
    require "shamu/attributes/validators"
    require "shamu/attributes/equality"
    require "shamu/attributes/camel_case"
    require "shamu/attributes/html_sanitation"
    require "shamu/attributes/trim_strings"
    require "shamu/attributes/unknown_attribute_error"
    require "shamu/attributes/hashed_id"

    def initialize(*attributes)
      assign_attributes(attributes.last)
    end

    # Project the current state of the object to a hash of attributes that can
    # be used to restore the attribute object at a later time.
    #
    # @param [Array, Regex] only include matching attributes
    # @param [Array, Regex] except matching attributes
    # @param [Boolean] set only include attributes that have actually been set.
    # @return [Hash] of attributes
    def to_attributes(only: nil, except: nil, set: false)
      self.class.attributes.each_with_object({}) do |(name, options), attrs|
        next if (only && !match_attribute?(only, name)) || (except && match_attribute?(except, name))
        next unless serialize_attribute?(name, options)
        next if set && !set?(name)

        attrs[name] = send(name)
      end
    end

    # @return [Hash] a hash with the keys for each of the given names.
    def slice(*names)
      to_attributes(only: names)
    end

    # Indicates if the object has an attribute with the given name. Aliased to
    # {#key?} to make the object look like a Hash.
    def attribute?(name)
      self.class.attributes.key?(name.to_sym)
    end
    alias key? attribute?

    # Access an attribute using a Hash like index.
    # @param [Symbol] name of the attribute.
    # @return [Object]
    def [](name)
      send(name) if attribute?(name)
    end

    # @param [Symbol] attribute name.
    # @return [Boolean] true if the attribute has been set.
    def set?(attribute)
      instance_variable_defined?(:"@#{attribute}")
    end

    # @return [Hash] the assigned attributes as a hash for JSON serialization.
    def as_json(options = {})
      to_attributes(**options.slice(:only, :except)).as_json
    end

    # @return [String] JSON encoded version of the assigned attributes.
    def to_json(options = {})
      as_json(options).to_json
    end

    def inspect
      result = "<#{self.class.name}:0x#{object_id.to_s(16)}"
      inspectable_attributes.map do |name|
        result << " #{name}=#{send(name).inspect}"
      end
      result << ">"
      result
    end

    def pretty_print(pp)
      pp.object_address_group(self) do
        pretty_print_custom(pp)
        pp.seplist(inspectable_attributes, -> { pp.text(",") }) do |name|
          pp.breakable(" ")
          pp.group(1) do
            pp.text(name.to_s)
            pp.text(":")
            pp.breakable(" ")
            pp.pp(send(name))
          end
        end
      end
    end

    private

      def inspectable_attributes
        to_attributes.keys
      end

      def pretty_print_custom(pp); end

      def match_attribute?(pattern, name)
        Array(pattern).any? do |matcher|
          matcher === name
        end
      end

      # Hook for derived objects to explicitly filter attributes included in
      # {#to_attributes}
      def serialize_attribute?(_name, options)
        options[:serialize]
      end

      # @!visibility public
      #
      # Assign a hash of values to the matching instance variables.
      #
      # @param [Hash] attributes to assign.
      #
      # @return [self]
      def assign_attributes(attributes)
        resolved_attributes = resolve_attributes(attributes)

        keys = resolved_attributes.keys

        self.class.attributes.each do |key, options|
          as = options[:as] # Alias support

          keys.delete(key)
          keys.delete(as) if as

          next unless resolved_attributes.key?(key) || (as && resolved_attributes.key?(as))

          value = resolved_attributes[key]
          value ||= resolved_attributes[as] if as

          if build = options[:build]
            value = build_value(build, value)
          end

          send(:"assign_#{key}", value)
        end

        handle_unknown_attribute(keys.first, attributes) if keys.present?

        self
      end

      def build_value(build, value)
        if build.is_a?(Class)
          build.new(value)
        elsif build.is_a?(Symbol)
          value.send(build)
        else
          build.call(value)
        end
      end

      def resolve_attributes(attributes)
        if attributes.respond_to?(:to_attributes)
          attributes.to_attributes
        # Allow protected attributes to be used without explicitly being set.
        # All 'Attributes' classes are themselves the explicit set of permitted
        # attributes so there is no danger of 'over assignment'.
        elsif attributes.respond_to?(:to_unsafe_h)
          attributes.to_unsafe_h
        elsif attributes.respond_to?(:to_hash)
          attributes.to_hash.symbolize_keys
        elsif attributes.respond_to?(:to_h)
          attributes.to_h.symbolize_keys
        else
          attributes
        end
      end

      def handle_unknown_attribute(key, attributes)
        # For hashes coming from rails requests, allow unexpected attributes.
        # They will be ignored but will not raise an error.
        return if attributes.respond_to?(:permit)

        # If we're given an attribute we don't know about then fail to avoid
        # unexpected typos or errors when changing attribute names.
        raise UnknownAttributeError.new(attribute: key, attribute_class: self.class.name)
      end

      class_methods do
        # @return [Hash] of attributes and their options defined on the class.
        def attributes
          @attributes ||= {}
        end

        # @return [Hash] of all association {.attributes} defined on the class.
        def associations
          attributes.select { |_, v| v[:association] }
        end

        def inherited(subclass)
          # Clone the base class's attributes into the subclass
          subclass.instance_variable_set(:@attributes, attributes.dup)
          super
        end

        # Define a new attribute for the class.
        #
        # @overload attribute(name, on:, default:, build:, &block )
        # @overload attribute(name, build, on:, default:, &block)
        #
        # @param [Symbol] name of the attribute.
        # @param [Symbol] as an alias of the attribute.
        # @param [Symbol] on another method on the class to delegate the attribute
        #     to.
        # @param [Object,#call] default value if not set.
        # @param [Class,#call] build method used to build a nested object on
        #     assignment of a hash with nested keys.
        # @param [Boolean] serialize true if the attribute should be included in
        #   {#to_attributes}. Default true.
        # @yieldreturn the value of the attribute. The result is memoized so the
        #     block is only invoked once.
        # @return [self]
        def attribute(name, *args, **options, &block)
          name    = name.to_sym
          options = create_attribute(name, *args, **options)

          define_attribute_reader(name, **options)
          define_attribute_assignment(name, **options, &block)

          if options.key?(:on)
            define_delegate_fetcher(name, options[:on], options[:build] || block)
          else
            define_virtual_fetcher(name, options[:default], &block)
          end

          private(:"fetch_#{name}")
          private(:"assign_#{name}")

          self
        end

        # # Define an {.attribute} that defines an association to another resource
        # # that also has it's own attributes.
        # #
        # # @param (see .attribute)
        # # @yieldreturn (see .attribute)
        # # @return [self]
        # def association( name, *args, **options, &block )
        #   options[:association] = true
        #
        #   attribute( name, *args, **options, &block )
        # end

        private

          # @return [Array<Symbol>] keys used by the {.attribute} method options
          #   argument. Used by {Attributes::Validation} to filter option keys.
          def attribute_option_keys
            %i[on build default serialize as]
          end

          def create_attribute(name, *args, **options)
            options = options.dup
            options[:build]     = args[0] if args.present?
            options[:serialize] = options.fetch(:serialize, true)
            attributes[name]    = options
          end

          def define_attribute_reader(name, as: nil, **)
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{name}                                           # def attribute
              return @#{name} if defined? @#{name}              #   return @attribute if defined? @attribute
              @#{name} = fetch_#{name}                          #   @attribute = fetch_attribute
            end                                                     # end

            def #{name}_set?                                      # def attribute_set?
              defined? @#{name}                                   #   defined? @attribute
            end                                                     # end
            RUBY

            alias_method(as, name) if as
          end

          def define_virtual_fetcher(name, default, &block)
            method_name = :"fetch_#{name}"

            if block_given?
              define_method(method_name, &block)
            elsif default.respond_to?(:call) && !default.is_a?(Symbol)
              define_method(method_name, &default)
            elsif default
              define_method(method_name) do
                default
              end
            else
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def fetch_#{name}; @#{name} end                   # def fetch_attribute; @attribute end
              RUBY
            end
          end

          def define_delegate_fetcher(name, on, builder)
            if builder
              define_method(:"build_#{name}") do |value|
                build_value(builder, value)
              end
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def fetch_#{name}                                   # fetch_attribute
                #{on} && build_#{name}( #{on}.#{name} )     #   target && build_attribute( target.attribute )
              end                                                   # end
              RUBY
            else
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def fetch_#{name}                                   # fetch_attribute
                #{on} && #{on}.#{name}                        #   target && target.attribute
              end                                                   # end
              RUBY
            end
          end

          def define_attribute_assignment(name, **, &block)
            mod = Module.new do
              module_eval <<-RUBY, __FILE__, __LINE__ + 1
              private def assign_#{name}( value )                   # assign_attribute( value )
                @#{name} = clean_#{name}_attribute( value  )      #   @attribute = clean_attribute_attribute( value )
              end                                                     # end

              private def clean_#{name}_attribute( value )          # clean_attribute( value )
                value                                                 #   value
              end                                                     # end
              RUBY
            end

            define_method("clean_#{name}_attribute", &block) if block

            include(mod)
          end
      end
  end
end
