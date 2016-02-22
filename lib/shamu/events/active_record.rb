module Shamu
  module Events

    # See {ActiveRecord::Service}
    module ActiveRecord
      require "shamu/events/active_record/service"
      require "shamu/events/active_record/message"
      require "shamu/events/active_record/channel"
      require "shamu/events/active_record/runner"
      require "shamu/events/active_record/migration"
    end
  end
end