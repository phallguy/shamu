require "shamu/rack"

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