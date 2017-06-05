module Shamu
  module Attributes
    module Validators
      # Validates that an attribute's value returns true for `valid?`.
      #
      # validates :nested_request, valid: true
      class ValidValidator < ActiveModel::EachValidator
        def validate_each( record, attribute, value )
          record.errors.add attribute, :invalid if value && !value.valid?
        end
      end
    end
  end
end
