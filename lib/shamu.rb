require "i18n"

I18n.load_path += Dir[ File.expand_path( "../shamu/locale/*.yml", __FILE__ ) ]

# A library for SOA based ruby systems.
module Shamu
  require "shamu/version"
  require "shamu/error"
  require "shamu/attributes"
  require "shamu/entities"
  require "shamu/services"
  require "shamu/to_model_id_extension"
end
