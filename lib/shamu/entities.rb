module Shamu
  # {include:file:lib/shamu/entities/README.md}
  module Entities
    require "shamu/entities/entity"
    require "shamu/entities/null_entity"
    require "shamu/entities/list"
    require "shamu/entities/list_scope"
    require "shamu/entities/identity_cache"
    require "shamu/entities/entity_path"
    require "shamu/entities/html_sanitation"
  end
end