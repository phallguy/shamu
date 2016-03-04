module Shamu
  # {include:file:lib/shamu/features/README.md}
  module Features
    require "shamu/features/context"
    require "shamu/features/toggle"
    require "shamu/features/conditions"
    require "shamu/features/selector"
    require "shamu/features/toggle_codec"
    require "shamu/features/env_store"
    require "shamu/features/features_service"
    require "shamu/features/config_service"
    require "shamu/features/list_scope"
    require "shamu/features/support"
    require "shamu/features/errors"
  end
end