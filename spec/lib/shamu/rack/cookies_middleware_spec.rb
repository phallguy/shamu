require "spec_helper"
require "shamu/rack"

module CookiesMiddlewareSpec
  class App
    include Scorpion::Rack
    attr_accessor :next

    def call( env )
      @next ||= proc { [ 200, {}, [ "Sting!" ] ] }
      @next.call( env, self )
    end
  end
end

describe Shamu::Rack::CookiesMiddleware do
  let(:app)                 { CookiesMiddlewareSpec::App.new }
  let(:scorpion_middleware) { Scorpion::Rack::Middleware.new( cookies_middleware ) }
  let(:cookies_middleware)  { Shamu::Rack::CookiesMiddleware.new( app ) }
  let(:request)             { Rack::MockRequest.new( scorpion_middleware ) }
  let(:response)            { request.get( "/" ) }

  it "prepares it with the environment" do

    app.next = proc do |env, app|
      cookies = app.send( :scorpion, env ).fetch Shamu::Rack::Cookies
      expect( cookies ).to be_a Shamu::Rack::Cookies
      [ 200, {}, [ "Yum!" ] ]
    end

    request.get "/"
  end
end