source "https://rubygems.org"

# Specify your gem"s dependencies in shamu.gemspec
gemspec

gem "activemodel", "~> 4.2.5"
gem "activerecord", "~> 4.2.5"
gem "sqlite3", "~> 1.3.11"
gem "kaminari", "~> 0.16.3", require: false

platforms :mri do
  gem "byebug"
  gem "pry-byebug"
end


group :test do

  gem "guard", "~> 2.12.8"
  gem "rubocop"
  gem "guard-rubocop"
  gem "spring"
  gem "guard-rspec"
  gem "fuubar"
  gem "yard"
  gem "simplecov", github: "colszowka/simplecov"
  gem "ruby_gntp", "~> 0.3.4"
  gem "awesome_print"

  gem "codeclimate-test-reporter", group: :test, require: nil
end