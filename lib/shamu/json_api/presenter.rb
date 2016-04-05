module Shamu
  module JsonApi

    # Present an object to a JSON API {ResourceBuilder builder}.
    class Presenter

      # Serialize the `resource` to the `builder`.
      #
      # @param [Object] resource to present.
      # @param [ResourceBuilder] builder to write to.
      # @return [void]
      def present( resource, builder )
        fail NotImplementedError
      end

    end
  end
end