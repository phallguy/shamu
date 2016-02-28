module Shamu
  module Features
    module Conditions

      # Match against the current host machine's name.
      class Hosts < Conditions::Condition

        # (see Condition#match?)
        def match?( context )
          hosts.any? { |h| h.match( context.host ) }
        end

        private

          def hosts
            @hosts ||= Array( config ).map do |entry|
              Regexp.new( entry, true )
            end
          end

      end

    end
  end
end