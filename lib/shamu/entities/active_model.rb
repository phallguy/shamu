require 'active_model'

module Shamu
  module Entities

    # Adds some convenience methods to make an entity work like an ActiveRecord
    # model and usable in url helpers, form helpers, etc.
    module ActiveModel
      extend ::ActiveModel::Naming
      include ::ActiveModel::Conversion

      # Entities are always immutable - so they are considered persisted. Use a
      # {Services::ChangeRequest} to back a form instead.
      def persisted?
        true
      end

      def self.included( base )
        super
        base.extend( Entities::ActiveModel::ModelName )
      end

      # Add model naming conventions for an entity class
      module ModelName
        # @return [ActiveModel::Name] used by url_helpers etc when generating
        #   model specific names for this entity.
        def model_name
          @model_name ||= begin
            base_name = name.sub /(::)?Entity$/, ''
            parts     = base_name.split '::'
            parts.shift if parts.length > 1
            parts[-1] = parts[-1].singularize
            base_name = parts.join '::'

            ::ActiveModel::Name.new( self, nil, base_name )
          end
        end
      end
    end
  end
end
