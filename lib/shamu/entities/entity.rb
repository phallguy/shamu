require "shamu/attributes"
require "shamu/to_model_id_extension"
require "active_model"

module Shamu
  module Entities

    # An entity is an abstract set of data returned from a {Services::Service}
    # describing the current state of an object.
    #
    # Entities are **immutable**. They will not change for the duration of the
    # request. Instead use a {Services::Service} to mutate the underlying data
    # and request an updated copy of the Entity.
    #
    # See {Shamu::Entities} for more on using entities.
    #
    # ## Helper Methods
    #
    # Entities can define helper methods to perform simple calculations or
    # projections of it's data. They only rely on state available by other
    # attribute projections. This makes the entity cacheable and serializable.
    #
    # ### Why class instead of module?
    #
    # The Entity class is ridiculously simple. It just mixes in a few modules
    # and adds a few helper methods. It could just as easily been implemented
    # as a module to mixin with POROs.
    #
    # While modules are generally preferred for non-domain specific behaviors,
    # in this case the purpose is to intentionally make it harder to mix the
    # responsibilities of an Entity class with another object in your project.
    # This tends to lead to better separation in your design.
    #
    # @example
    #
    #   class LiveAccount < Shamu::Entities::Entity
    #
    #     # Use an ActiveRecord User model for the actual data. Not accessible
    #     # to callers.
    #     model :user
    #
    #     # Simple projections
    #     attribute :name, on: :user
    #     attribute :email, on: :user
    #
    #     # Computed projections. Only calculated once, then cached in the
    #     # entity instance.
    #     attribute :signed_up_on do
    #       I18n.localize( user.created_at )
    #     end
    #
    #     attribute :last_login_at do
    #       user.login_reccords.last
    #     end
    #
    #     # Project another model
    #     model :contact
    #
    #     # Project a JSON object using another entity class
    #     attribute :address, AddressEntity, on: :contact
    #
    #     # Helper method
    #     def new_user?
    #       signed_up_on > 3.days.ago
    #     end
    #   end
    #
    class Entity
      include Shamu::Attributes
      include Shamu::ToModelIdExtension::Models

      # @return [false] real entities are not empty. See {NullEntity}.
      def empty?
        false
      end
      alias_method :blank?, :empty?

      # @return [true] the entity is present. See {NullEntity}.
      def present?
        !empty?
      end

      # Entities are always immutable - so they are considered persisted. Use a
      # {Services::ChangeRequest} to back a form instead.
      def persisted?
        true
      end

      private

        def serialize_attribute?( name, options )
          super && !options[:model]
        end

      class << self

        # @return [ActiveModel::Name] used by url_helpers etc when generating
        #   model specific names for this entity.
        def model_name
          @model_name ||= begin
            base_name = name.sub /(::)?Entity$/, ""
            parts     = base_name.split "::"
            parts[-1] = parts[-1].singularize
            base_name = parts.join "::"

            ::ActiveModel::Name.new( self, nil, base_name )
          end
        end

        private

          # @!visibility public
          # Define a model attribute that the entity will project. Use additional
          # {.attribute} calls to define the actual projections.
          #
          # Model attributes are _private_ and should never be exposed to any
          # client from another domain. Instead project only the properties needed
          # for the Entity's clients.
          #
          # @param (see Shamu::Attributes::DSL#attribute)
          # @return [self]
          #
          # @example
          #
          #   class Account < Shamu::Entities::Entity
          #     model :user
          #
          #     attribute :username, on: :user
          #     attribute :email, on: :user
          #   end
          def model( name, **args, &block )
            attribute( name, **args, &block )
            attributes[name][:model] = true
            private name
          end

          # Redefined to prevent creating mutable attributes.
          def attr_accessor( * )
            fail "Remember, an Entity is immutable. Use a Services::Service to mutate the underlying data."
          end

          # Redefined to prevent creating mutable attributes.
          def attr_writer( * )
            fail "Remember, an Entity is immutable. Use a Services::Service to mutate the underlying data."
          end
      end
    end
  end
end