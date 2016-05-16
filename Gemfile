source "https://rubygems.org"

# Specify your gem"s dependencies in shamu.gemspec
gemspec

group :test do
  gem "activerecord", "~> 4.2.5"
  gem "actionpack", "~> 4.2.5"
  gem "responders", "~> 2.1.2"
  gem "kaminari", "~> 0.16.3", require: false

  gem "byebug"
  gem "pry-byebug"

  gem "sqlite3", "~> 1.3.11"
  gem "guard", "~> 2.12.8"
  gem "rubocop", "~> 0.39.0"
  gem "guard-rubocop"
  gem "spring"
  gem "guard-rspec"
  gem "rspec-its"
  gem "rspec-wait"
  gem "rspec-rails", require: false
  gem "fuubar"
  gem "yard"
  gem "yard-activesupport-concern"
  gem "simplecov", github: "colszowka/simplecov"
  gem "ruby_gntp", "~> 0.3.4"
  gem "awesome_print"

  gem "codeclimate-test-reporter", group: :test, require: nil
  gem "rspec_junit_formatter", "~> 0.2.2", platforms: :mri
end