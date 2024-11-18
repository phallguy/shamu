require "active_model"

module Shamu
  module Attributes
    # Defines an interface for entities that report validation failures with
    # respect to their attributes.
    module Validation
      extend ActiveSupport::Concern

      included do |base|
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes

        base.include(::ActiveModel::Validations)
        base.include(Validation::Overrides)
      end

      # @return [Boolean] if the object is free from validation errors. Must
      #   call {#validate} before checking.
      def valid?
        errors.blank?
      end

      # @return [Boolean] true if the object has been validated at least once.
      def validated?
        @validated
      end

      class_methods do
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
        def attribute(name, *args, **options, &block)
          super

          validation_options = options.each_with_object({}) do |(key, value), opts|
            next if attribute_option_keys.include?(key)

            validator = "#{key.to_s.camelize}Validator"
            if Shamu::Attributes::Validators.const_defined?(validator.to_sym)
              key = "shamu/attributes/validators/#{key}"
            end
            opts[key] = value
          end
          validates(name, **validation_options) if validation_options.any?
        end
      end

      # Overrides ActiveModel::Validation behavior to match Shamu validation
      # behaviors.
      module Overrides
        # @return [Boolean] true if there are no errors reported manually or
        #     through {Validation#validate}.
        def valid?
          validate unless validated?
          errors.empty?
        end

        # Validate the attributes and expose any errors via {#errors}.
        def validate
          @validated = true
          run_validations!
        end

        private

          def assign_attribute!(*)
            # If any attribute changes we should re-run the validations
            @validated = false
            super
          end
      end
    end
  end
end
