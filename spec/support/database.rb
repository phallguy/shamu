require "active_record"

# Prevent kaminari warning since we're not using a framework
module Sinatra
end

require "kaminari"
Kaminari::Hooks.init


if RUBY_PLATFORM == 'java' then
  require 'jdbc/sqlite3'
  Jdbc::SQLite3.load_driver
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "test.db"
)
