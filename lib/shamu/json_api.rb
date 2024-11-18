module Shamu
  # {include:file:lib/shamu/json_api/README.md}
  module JsonApi
    MIME_TYPE = "application/vnd.api+json".freeze

    require "shamu/json_api/context"
    require "shamu/json_api/builder_methods"
    require "shamu/json_api/collection_builder"
    require "shamu/json_api/relationship_builder"
    require "shamu/json_api/resource_builder"
    require "shamu/json_api/response"
    require "shamu/json_api/presenter"
    require "shamu/json_api/error"
    require "shamu/json_api/error_builder"
  end
end