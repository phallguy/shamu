module Shamu
  module Entities
    # Forces all string attributes to be html sanitized.
    module HtmlSanitation
      extend ActiveSupport::Concern

      included do
        include Shamu::Attributes::HtmlSanitation
        extend AttributeMethod
      end

      module AttributeMethod
        # (see Attributes::HtmlSanitation.attribute)
        def attribute(name, *args, **options, &block)
          options[:html] ||= :none

          super
        end
      end
    end
  end
end