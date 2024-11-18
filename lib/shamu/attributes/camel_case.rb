module Shamu
  module Attributes
    # Automatically add camelCase aliases for all attributes.
    module CamelCase
      extend ActiveSupport::Concern

      included do |base|
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
      end

      class_methods do
        def attribute(name, *args, **options, &block)
          options[:as] ||= name.to_s.camelize(:lower).to_sym
          super
        end
      end
    end
  end
end
