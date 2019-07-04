require "active_record"

# Prevent kaminari warning since we're not using a framework
module Sinatra
end

require "kaminari"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "test.db"
)
