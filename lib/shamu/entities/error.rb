require "i18n"

module Shamu
  module Entities
    # A generic error class for problems with shamu services.
    class Error < Shamu::Error
      private

        def translation_scope
          super.dup.insert(1, :entities)
        end
    end

    class ListScopeInvalidError < Error
      def initialize(message = :list_scope_invalid)
        super(translate(message))
      end
    end
  end
end
