require "shamu/rack"
require "shamu/json_api"

module Shamu
  module Rails

    # Integrate Shamu with rails.
    class Railtie < ::Rails::Railtie

      rake_tasks do
        rake_path = File.expand_path( "../../tasks/*.rake" )
        Dir[ rake_path ].each { |f| load f }
      end

      initializer "shamu.configure" do
        if defined? ::ActionController
          ::ActionController::Base.send :include, Shamu::Rails::Controller
          ::ActionController::Base.send :include, Shamu::Rails::Entity
          ::ActionController::Base.send :include, Shamu::Rails::Features

          Mime::Type.register Shamu::JsonApi::MIME_TYPE, :json_api

          ActionController::Renderers.add :json_api do |obj, _options|
            self.content_type ||= Mime[:json_api]
            obj
          end
        end
      end

      initializer "shamu.insert_middleware" do |app|
        app.config.middleware.use "Scorpion::Rack::Middleware"
        app.config.middleware.use "Shamu::Rack::CookiesMiddleware"
        app.config.middleware.use "Shamu::Rack::QueryParamsMiddleware"
      end

    end
  end
end