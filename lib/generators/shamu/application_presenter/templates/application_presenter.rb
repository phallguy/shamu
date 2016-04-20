# Base {Shamu::JsonApi::Presenter} that all other presenters should
# inherit from.
class ApplicationPresenter < Shamu::JsonApi::Presenter
  include ::Rails.application.routes.url_helpers

  # Override default_url_options in config/environments files.
  self.default_url_options = Rails.application.config.shamu.json_api.default_url_options
end