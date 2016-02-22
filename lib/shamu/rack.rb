require "scorpion/rack/middleware"

module Shamu

  # {include:file:lib/shamu/rack/README.md}
  module Rack
    require "shamu/rack/cookies"
    require "shamu/rack/cookies_middleware"
  end
end