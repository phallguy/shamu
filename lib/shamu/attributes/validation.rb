module Shamu
  module Attributes

    # Defines an interface for entities that report validation failures with
    # respect to their attributes.
    #
    # This mixin does not define any validation methods itself. Instead use
    # more specific validation mixin for your desired framework. For example the
    # {ActiveModelValidation} mixin.
    module Validation

      def self.included( base )
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
        base.extend( Validation::DSL )
        super
      end

      # Extend the {Attributes::DSL} to support validation on defined attributes.
      module DSL

        # Adds validation options to {Attributes::DSL#attribute}. Any option not
        # recognized by one of the Attributes mixins will be used as validation
        # arguments for the given attribute.
        #
        # @example
        #   attribute :email, presence: true
        #
        #   # Results in
        #   attribute :email
        #   validates :email, presence: true
        def attribute( name, *args, **options, &block )
          super

          validation_options = options.except( *attribute_option_keys )
          validates name, validation_options if validation_options.any?
        end

        # Define validation rules for an attribute.
        def validates( _name, **_options )
          fail NotImplementedError, "include a validation framework such as Shame::Attributes::ActiveModelValidation"
        end
      end
    end
  end
end
