module Shamu

  # Rails integration.
  module Rails
    require "shamu/rails/entity"
    require "shamu/rails/controller"
    require "shamu/rails/features"
    require "shamu/rails/json_api"
    require "shamu/rails/railtie"
  end
end