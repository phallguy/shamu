require "spec_helper"

require "combustion"

Combustion.initialize! :action_controller do
  require "shamu/rails"
end

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end