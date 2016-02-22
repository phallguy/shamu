require "i18n"

module Shamu

  module Events
    # A generic error class for problems with shamu services.
    class Error < Shamu::Error
      private

        def translation_scope
          super.dup.insert( 1, :events )
        end
    end

    # A an event runner did not provide a valid runner_id.
    class UnknownRunnnerError < Error

      def initialize( message = :unknown_runner )
        super
      end

    end
  end
end