require "i18n"

module Shamu

  # A generic error class for problems in the shamu library.
  class Error < StandardError

    private

      def translate( key, args = {} )
        I18n.translate key, args.merge( scope: [ :shamu, :errors, :messages ] )
      end

  end
end