require "shamu/rack"
require "shamu/json_api"

module Shamu
  module Rails
    # Integrate Shamu with rails.
    class Railtie < ::Rails::Railtie
      rake_tasks do
        rake_path = File.expand_path("../../tasks/*.rake")
        Dir[rake_path].each { |f| load f }
      end

      initializer "shamu.configure" do
        config.shamu = ActiveSupport::OrderedOptions.new
        config.shamu.json_api = ActiveSupport::OrderedOptions.new
        config.shamu.json_api.default_url_options = {}

        if defined? ::ActionController
          controller_classes = [::ActionController::Base]
          controller_classes << ::ActionController::API if defined? ::ActionController::API

          controller_classes.each do |klass|
            klass.send(:include, Shamu::Rails::Controller)
            klass.send(:include, Shamu::Rails::Entity)
            klass.send(:include, Shamu::Rails::Features)
          end

          Mime::Type.register(Shamu::JsonApi::MIME_TYPE, :json_api)

          ActionController::Renderers.add(:json_api) do |obj, _options|
            self.content_type ||= Mime[:json_api]
            obj
          end
        end
      end

      initializer "shamu.insert_middleware" do |app|
        if defined? ::ActionDispatch
          app.config.middleware.insert_after(ActionDispatch::Cookies, Shamu::Rails::CookiesMiddleware)
        else
          app.config.middleware.use(Shamu::Rack::CookiesMiddleware)
        end
        app.config.middleware.use(Shamu::Rack::QueryParamsMiddleware)
      end
    end
  end
end
