require "scorpion/rack/middleware"

module Shamu
  # {include:file:lib/shamu/rack/README.md}
  module Rack
    require "shamu/rack/cookies"
    require "shamu/rack/cookies_middleware"
    require "shamu/rack/query_params"
    require "shamu/rack/query_params_middleware"
  end
end