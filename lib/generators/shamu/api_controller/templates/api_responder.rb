class ApiResponder < ActionController::Responder
  include Responders::HttpCacheResponder
  include Shamu::JsonApi::Rails::Responder
end
