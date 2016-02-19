module Shamu

  # Logging class for shamu {Services}.
  class Logger < ::Logger

    # Set up a default logger.
    def self.create( scorpion, *args, **dependencies, &block )
      args = [STDOUT] unless args.present?
      ::Logger.new( *args )
    end

  end
end