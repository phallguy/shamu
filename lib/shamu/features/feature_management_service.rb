module Shamu
  module Features

    # ...
    class FeatureManagementService < Services::Service
      include Security::Support


      def enable( name, user_id = nil )
      end

      def disable( name, user_id = nil )
      end

      def list
      end

    end
  end
end