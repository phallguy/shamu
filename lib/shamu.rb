require "i18n"

I18n.load_path += Dir[ File.expand_path( "../shamu/locale/*.yml", __FILE__ ) ]

# {include:file:README.md}
module Shamu
  require "shamu/version"
  require "shamu/error"
  require "shamu/attributes"
  require "shamu/entities"
  require "shamu/logger"
  require "shamu/services"
  require "shamu/security"
  require "shamu/events"
  require "shamu/sessions"
  require "shamu/features"
  require "shamu/to_model_id_extension"
  require "shamu/to_bool_extension"

  require "shamu/rails" if defined? Rails
end
