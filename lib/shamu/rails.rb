module Shamu

  # Rails integration.
  module Rails
    require "shamu/rails/entity"
    require "shamu/rails/controller"
    require "shamu/rails/features"
    require "shamu/rails/json_api"
    require "shamu/rails/json_api_responder"
    require "shamu/rails/railtie"
    require "shamu/rails/application_presenter"
  end
end