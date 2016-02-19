require "i18n"

module Shamu

  module Services
    # A generic error class for problems with shamu services.
    class Error < Shamu::Error
      private

        def translate( key, **args )
          I18n.translate key, args.merge( scope: [ :shamu, :services, :errors, :messages ] )
        end
    end

    # The service has included a module that requires some setup or
    # configuration but it hasn't been setup properly.
    class IncompleteSetupError < Error
      def initialize( message = :incomplete_setup )
        super
      end
    end
  end
end