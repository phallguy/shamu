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

      # Validate the attributes and expose any errors via {#errors}.
      def validate
        fail NotImplementedError, "include a validation framework such as Shamu::Attributes::ActiveModelValidation"
      end

      # @!method errors
      # @return the list of errors on the object defined by the chosen
      #     validation framework.
      def errors
        fail NotImplementedError, "include a validation framework such as Shamu::Attributes::ActiveModelValidation"
      end

      # @return [Boolean] if the object is free from validation errors. Must
      #   call {#validate} before checking.
      def valid?
        errors.blank?
      end

      # Extend the {Attributes::DSL} to support validation on defined attributes.
      module DSL

        # Adds validation options to {Attributes::DSL#attribute}. Any option not
        # recognized by one of the Attributes mixins will be used as validation
        # arguments for the given attribute.
        #
        # @overload attribute( name, build, **options )
        # @param (see Attributes::Assignment::DSL#attribute)
        # @return (see Attributes::Assignment::DSL#attribute)
        #
        # @example
        #   attribute :email, presence: true
        #
        #   # Results in
        #   attribute :email
        #   validates :email, presence: true
        def attribute( name, *args, **options, &block )
          super

          validation_options = options.each_with_object({}) do |(key, value), opts|
            opts[key] = value unless attribute_option_keys.include?( key )
          end
          validates name, validation_options if validation_options.any?
        end

        # Define validation rules for an attribute.
        #
        # See the validation framework specific mixin for details on validation
        # rules.
        #
        # @overload validates( name, **validations )
        # @param [Symbol] name of the attribute to validate.
        # @param [Hash] validations to apply.
        # @return [void]
        def validates( _name, **_validations )
          fail NotImplementedError, "include a validation framework such as Shamu::Attributes::ActiveModelValidation"
        end
      end
    end
  end
end
