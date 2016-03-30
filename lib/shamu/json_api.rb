module Shamu
  # {include:file:lib/shamu/json_api/README.md}
  module JsonApi
    require "shamu/json_api/context"
    require "shamu/json_api/relationship_builder"
    require "shamu/json_api/resource_builder"
    require "shamu/json_api/response"
    require "shamu/json_api/serializer"
    require "shamu/json_api/support"
    require "shamu/json_api/error"
    require "shamu/json_api/error_builder"
  end
end