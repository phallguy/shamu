module Shamu
  # {include:file:lib/shamu/entities/README.md}
  module Entities
    require "shamu/entities/entity"
    require "shamu/entities/null_entity"
    require "shamu/entities/list"
    require "shamu/entities/paged_list"
    require "shamu/entities/list_scope"
    require "shamu/entities/identity_cache"
    require "shamu/entities/entity_path"
    require "shamu/entities/html_sanitation"
    require "shamu/entities/entity_lookup_service"
    require "shamu/entities/opaque_id"
    require "shamu/entities/opaque_entity_lookup_service"
  end
end
