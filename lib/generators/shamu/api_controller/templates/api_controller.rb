require "api_responder"

class ApiController < ApplicationController
  include Shamu::JsonApi::Rails::Controller

  self.responder = ::ApiResponder

  respond_to :json_api, :json
end