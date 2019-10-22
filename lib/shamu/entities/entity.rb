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
    #       user.login_records.last
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
      include Shamu::Attributes::Equality
      include Shamu::ToModelIdExtension::Models

      extend ActiveModel::Naming
      include ActiveModel::Conversion

      # @!attribute
      # @return [Object] id of the entity.
      #
      # Shamu makes the assumption that all entities will have a single unique
      # identifier that can be used to distinguish the entity from other
      # instances of the same class.
      #
      # While not strictly necessary in an purely abstract service, this
      # invariant significantly reduces the complexity of caching, lookups and
      # other helpful conventions and is almost always true in most modern
      # architectures.
      #
      # If an Entity does not have a natural primary key id, an id may be
      # generated by joining the values of the composite key that is used to
      # identify the resource.
      def id
        fail "No id attribute defined. Add `attribute :id, on: :record` to #{ self.class.name }"
      end

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
      # {Services::Request} to back a form instead.
      def persisted?
        true
      end

      # @return [self]
      def to_entity
        self
      end

      # Redact attributes on the entity.
      #
      # @param [Array<Symbol>,Hash] attributes to redact on the entity. Either
      # a list of attributes to set to nil or a hash of attributes with their
      # values.
      def redact!( *attributes )
        hash =
          if attributes.first.is_a?( Symbol )
            Hash[ attributes.zip( [ nil ] * attributes.length ) ]
          else
            attributes.first
          end

        assign_attributes hash
        @redacted = true
        self
      end

      # Redact attributes on the entity.
      #
      # @param [Array<Symbol>,Hash] attributes to redact on the entity. Either
      # a list of attributes to set to nil or a hash of attributes with their
      # values.
      # @return [Entity] a modified version of the entity with the given
      # attributes redacted.
      def redact( *attributes )
        hash =
          if attributes.first.is_a?( Symbol )
            Hash[ attributes.zip( [ nil ] * attributes.length ) ]
          else
            attributes.first
          end

        self.class.new( to_attributes.merge( hash ) )
      end

      def ==(other)
        return true if super

        # Match model instances
        self.class.attributes.find do |key, attr|
          next unless attr[:model]

          self[key] == other
        end
      end

      private

        def pretty_print_custom( pp )
          pp.text " [REDACTED] " if @redacted
        end

        def serialize_attribute?( name, options )
          super && !options[:model]
        end

        def attribute_eql?( other, name )
          value = send( name )
          other_value = other.send( name )

          if value.is_a?( Entity ) || other_value.is_a?( Entity )
            return value.id.eql?( other_value.id )
          else
            super
          end
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

        # Define custom default attributes for a {NullEntity} for this class.
        # @return [Class] the {NullEntity} class for the entity.
        #
        # @example
        #
        #   class Users::UserEntity < Shamu::Entities::Entity
        #     attribute :id
        #     attribute :name
        #     attribute :level
        #
        #     null_entity do
        #       attribute :level do
        #         "Guest"
        #       end
        #     end
        #   end
        def null_entity( &block )
          null_class = ::Shamu::Entities::NullEntity.for( self )
          null_class.class_eval( &block ) if block_given?
          null_class
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
            attributes[name][:ignore_equality] = true
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
