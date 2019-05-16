require "simplecov"
SimpleCov.start

require "pry"
require "bundler/setup"

require "shamu"
require "shamu/rspec"
require "scorpion/rspec"
require "rspec/wait"
require "rspec/its"

root_path = File.expand_path( "..", __dir__ )

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[ File.join( root_path, "spec/support/**/*.rb" ) ].each { |f| require f }

RSpec.configure do |config|

  config.order = "random"

  config.filter_gems_from_backtrace "activesupport", "actionpack", "actionview", "scorpion-ioc", "rspec-wait",
                                    "rspec-core", "rspec", "rspec-support", "rspec-expectations"

  config.filter_run focus: true
  config.filter_run_excluding :broken => true
  config.run_all_when_everything_filtered = true

  config.include Scorpion::Rspec::Helper
  config.extend  Support::ActiveRecord

  config.before(:all) do
    Shamu::Security.private_key = SecureRandom.base64( 128 )
  end

end
