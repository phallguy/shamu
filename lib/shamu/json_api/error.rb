require "i18n"

module Shamu

  module JsonApi
    # A generic error class for problems with shamu JSON API.
    class Error < Shamu::Error
      private

        def translation_scope
          super.dup.insert( 1, :json_api )
        end

    end

    # Raised if an {ResourceBuilder#identifier} was not built.
    class IncompleteResourceError < Error
      def initialize( message = :incomplete_resource )
        super
      end
    end

    class IdentifierRequiredError < Error
      def initialize( message = :identifier_required )
        super
      end
    end
  end
end