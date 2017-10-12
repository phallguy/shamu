source "https://rubygems.org"

# Specify your gem"s dependencies in shamu.gemspec
gemspec

gem "rake"

group :test do
  gem "activerecord", "~> 5.0"
  gem "actionpack", "~> 5.0"
  gem "responders", "~> 2.1.2"
  gem "kaminari", "~> 0.16.3", require: false

  gem "byebug", "9.0.6"
  gem "pry-byebug"

  gem "sqlite3", "~> 1.3.11"
  gem "guard", "~> 2.12.8"
  gem "rubocop", "~> 0.49.0"
  gem "guard-rubocop"
  gem "spring"
  gem "guard-rspec"
  gem "rspec-its"
  gem "rspec-wait"
  gem "rspec-rails", require: false
  gem "fuubar"
  gem "yard"
  gem "yard-activesupport-concern"
  gem "simplecov", "~> 0.14"
  gem "ruby_gntp", "~> 0.3.4"
  gem "awesome_print"

  gem "nokogiri", "1.8.0"

  gem "codeclimate-test-reporter", "~> 1.0 ", group: :test, require: nil
  gem "rspec_junit_formatter", "~> 0.2.2", platforms: :mri
end
