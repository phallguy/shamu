require "active_model"

module Shamu
  module Attributes

    # Allows the use of ActiveModel validation methods for an {Attributes}
    # object.
    module ActiveModelValidation

      def self.included( base )
        base.include( Attributes::Validation )
        base.include( ::ActiveModel::Validations )
        base.include( ActiveModelValidation::Overrides )
        super
      end

      # Overrides ActiveModel::Validation behavior to match Shamu validation
      # behaviors.
      module Overrides

        def valid?
          errors.empty?
        end

        def validate
          run_validations!
        end

        def errors
          @wrapped_errors ||= ActiveModelValidation::Errors.new( self, super )
        end

      end

      # Simple wrapper to make ActiveModel::Errors look like {Shamu::Errors}.
      class Errors < Shamu::Errors

        def initialize( base, errors )
          super( base )
          @errors = errors
        end

        # Proxy Shamu methods to ActiveModel::Errors object.
        %i( add include? has_key? key? empty? each ).each do |method|
          define_method method do |*args, &block|
            @errors.send method, *args, &block
          end
        end

      end
    end
  end
end
