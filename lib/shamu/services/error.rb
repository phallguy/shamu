require "i18n"

module Shamu

  module Services
    # A generic error class for problems with shamu services.
    class Error < Shamu::Error
      private

        def translation_scope
          super.dup.insert( 1, :services )
        end

    end

    # The service has included a module that requires some setup or
    # configuration but it hasn't been setup properly.
    class IncompleteSetupError < Error
      def initialize( message = :incomplete_setup )
        super
      end
    end

    class ServiceRequestFailedError < Error
      attr_reader :result
      attr_reader :full_messages

      def initialize( result )
        @result = result
        @full_messages = result.errors.full_messages.join( ", " )

        super translate( :service_request_failed, errors: @full_messages )
      end
    end
  end
end
