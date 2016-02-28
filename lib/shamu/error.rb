require "i18n"

module Shamu

  # A generic error class for problems in the shamu library.
  class Error < StandardError
    private

      def translation_scope
        [ :shamu, :errors ]
      end

      def translate( key, **args )
        I18n.translate key, args.merge( scope: translation_scope )
      end
  end

  # The resource was not found.
  class NotFoundError < Error
    def initialize( message = :not_found )
      super translate( message )
    end
  end

  # The method is not implemented.
  class NotImplementedError < Error
    def initialize( message = :not_implemented )
      super translate( message )
    end
  end
end