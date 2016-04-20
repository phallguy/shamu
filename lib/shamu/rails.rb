module Shamu

  # Rails integration.
  module Rails
    require "shamu/rails/entity"
    require "shamu/rails/controller"
    require "shamu/rails/features"
    require "shamu/rails/railtie"
    require "shamu/json_api/rails"
  end
end