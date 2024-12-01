module Shamu
  # Rails integration.
  module Rails
    require "scorpion/rails"
    require "shamu/rails/entity"
    require "shamu/active_record"
    require "shamu/rails/controller"
    require "shamu/rails/features"
    require "shamu/rails/cookies"
    require "shamu/rails/cookies_middleware"
    require "shamu/rails/railtie"
    require "shamu/json_api/rails"
  end
end