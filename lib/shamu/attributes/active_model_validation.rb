require "active_model"

module Shamu
  module Attributes

    # Allows the use of ActiveModel validation methods for an {Attributes}
    # object.
    module ActiveModelValidation

      def self.included( base )
        base.include( ::ActiveModel::Validations )
        base.extend( Attributes::Validation )
        super
      end

    end
  end
end
