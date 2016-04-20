require "api_responder"

class ApiController < ApplicationController
  include Shamu::Rails::JsonApi

  self.responder = ::ApiResponder

  respond_to :json, :json_api
end