module Shamu
  module Rails
    # Add support for testing for feature toggles to controllers and views.
    module Features
      extend ActiveSupport::Concern

      included do
        include Shamu::Features::Support
      end
    end
  end
end