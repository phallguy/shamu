require 'i18n'

I18n.load_path += Dir[ File.expand_path( '../shamu/locale/*.yml', __FILE__ ) ]

module Scorpion

  require 'shamu/version'
  require 'shamu/error'

end
