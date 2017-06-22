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
    attr_reader :id
    attr_reader :resource

    def initialize( message = :not_found, id: :not_set, resource: :not_set )
      @id = id
      @resource = resource

      if message == :not_found
        message =
          if id != :not_set
            if resource != :not_set
              :resource_not_found_with_id
            else
              :not_found_with_id
            end
          elsif resource != :not_set
            :resource_not_found
          else
            :not_found
          end
      end

      super translate( message, id: id, resource: resource )
    end
  end

  # The method is not implemented.
  class NotImplementedError < Error
    def initialize( message = :not_implemented )
      super translate( message )
    end
  end
end
