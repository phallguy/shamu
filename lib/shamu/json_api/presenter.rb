module Shamu
  module JsonApi

    # Presenters are responsible for projecting an {Entities::Entity} or PORO
    # to a well-formatted JSON API {ResourceBuilder builder} response.
    #
    # {Presenter} delegates all of the {ResourceBuilder} methods for convenient
    # syntax.
    #
    # ```
    # class UserPresenter < ApplicationPresenter
    #   def present
    #     identifier :user, resource.id
    #
    #     attributes name: resource.name,
    #                email: resource.email
    #
    #     relationship( :address ) do |rel|
    #       rel.identifier :address, resource.address_id
    #       rel.link :related, user_address_url( resource, resource.address_id )
    #     end
    #   end
    # end
    # ```
    class Presenter

      # @param [Object] resource to presenter.
      # @param [ResourceBuilder] builder used to build the JSON API response.
      def initialize( resource, builder )
        @resource = resource
        @builder  = builder
      end

      # Serialize the `resource` to the `builder`.
      #
      # @return [void]
      def present
        fail NotImplementedError
      end

      private

        delegate :relationship, :attribute, :attributes, :link, :identifier, :meta, to: :builder

        attr_reader :resource
        attr_reader :builder

    end
  end
end