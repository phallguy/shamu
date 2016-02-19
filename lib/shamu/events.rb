module Shamu
  # {include:file:lib/shamu/events/README.md}
  module Security
    require "shamu/events/error"
    require "shamu/events/message"
    require "shamu/events/events_service"
    require "shamu/events/channel_stats"
    require "shamu/events/support"

    require "shamu/events/in_memory"
  end
end