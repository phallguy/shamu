module Shamu
  module Features
    module Conditions
      # Match against the current date and time.
      class ScheduleAt < Conditions::Condition
        # (see Condition#match?)
        def match?(context)
          context.time >= timestamp
        end

        private

          def timestamp
            @timestamp ||=
              case config
              when Date   then config.to_time
              when String then Time.zone ? Time.zone.parse(config) : Time.parse(config)
              end
          end
      end
    end
  end
end