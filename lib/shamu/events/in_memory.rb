module Shamu
  module Events

    # See {Service}.
    module InMemory
      require "shamu/events/in_memory/service"
      require "shamu/events/in_memory/async_service"
    end
  end
end