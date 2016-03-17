require "spec_helper"
require "shamu/rack"

module QueryParamsMiddlewareSpec
  class App
    include Scorpion::Rack
    attr_accessor :next

    def call( env )
      @next ||= proc { [ 200, {}, [ "Sting!" ] ] }
      @next.call( env, self )
    end
  end
end

describe Shamu::Rack::QueryParamsMiddleware do
  let(:app)                     { QueryParamsMiddlewareSpec::App.new }
  let(:scorpion_middleware)     { Scorpion::Rack::Middleware.new( query_parmas_middleware ) }
  let(:query_parmas_middleware) { Shamu::Rack::QueryParamsMiddleware.new( app ) }
  let(:request)                 { Rack::MockRequest.new( scorpion_middleware ) }
  let(:response)                { request.get( "/" ) }

  it "prepares it with the environment" do

    app.next = proc do |env, app|
      query_parmas = app.send( :scorpion, env ).fetch Shamu::Rack::QueryParams
      expect( query_parmas ).to be_a Shamu::Rack::QueryParams
      [ 200, {}, [ "Yum!" ] ]
    end

    request.get "/"
  end
end