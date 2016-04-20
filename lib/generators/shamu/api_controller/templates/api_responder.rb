class ApiResponder < ActionController::Responder
  include Responders::HttpCacheResponder
  include Shamu::Rails::JsonApiResponder
end
