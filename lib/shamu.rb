require "i18n"

I18n.load_path += Dir[File.expand_path("shamu/locale/*.yml", __dir__)]

# {include:file:README.md}
module Shamu
  require "shamu/scorpion"
  require "shamu/version"
  require "shamu/error"
  require "shamu/attributes"
  require "shamu/entities"
  require "shamu/logger"
  require "shamu/services"
  require "shamu/security"
  require "shamu/auditing"
  require "shamu/events"
  require "shamu/sessions"
  require "shamu/features"
  require "shamu/json_api"
  require "shamu/to_model_id_extension"
  require "shamu/to_bool_extension"
  require "shamu/extensions/composite_name"
  require "shamu/extensions/inspectable"

  require "shamu/rails" if defined? ::Rails
end
