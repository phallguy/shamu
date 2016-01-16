require 'i18n'

module Schamu
  class Error < StandardError

    private
      def translate( key, args = {} )
        I18n.translate key, args.merge( scope: [:shamu,:errors,:messages] )
      end
  end


end