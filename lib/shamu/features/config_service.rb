module Shamu
  module Features

    # Present a unified get/set interface for some distributed feature
    # configuration stored in an external persistence system (redis,
    # ActiveRecord, consul, etc, etc.).
    class ConfigService < Services::Service
    end
  end
end