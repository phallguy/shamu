module Shamu
  module Rails

    # Base presenter that supports rails url builders.
    class ApplicationPresenter < Shamu::JsonApi::Presenter
      include ::Rails.application.routes.url_helpers

      self.default_url_options = Rails.application.config.shamu.json_api.default_url_options
    end
  end
end