module Shamu
  module Entities

    # Null entities look at feel just like their natural counterparts but are
    # not backed by any real data. Rather than returning null from a service
    # lookup function, services will return a null entity so that clients do not
    # need to constantly check for nil before formatting output.
    #
    # ```
    # class UserEntity < Entity
    #   attribute :name
    #   attribute :id
    #   attribute :email
    # end
    #
    # class NullUserEntity < UserEntity
    #   include NullEntity
    # end
    #
    # user = user_service.lookup( real_user_id )
    # user       # => UserEntity
    # user.name  # => "Shamu"
    # user.email # => "start@seaworld.com"
    # user.id    # => 5
    #
    # user = user_service.lookup( unknown_user_id )
    # user       # => NullUserEntity
    # user.name  # => "Unknown User"
    # user.email # => nil
    # user.id    # => nil
    # ```
    module NullEntity

      # Attributes to automatically format as "Unknown {Entity Class Name}"
      AUTO_FORMATTED_ATTRIBUTES = %i( name title label ).freeze

      # @return [nil]
      # Prevent rails url helpers from generating URLs for the entity.
      def to_param
      end

      # @return [true]
      #
      # Allow clients to adjust behavior if needed for missing entities.
      def empty?
        true
      end

      def self.included( base )
        AUTO_FORMATTED_ATTRIBUTES.each do |attr|
          next unless base.attributes.key?( attr )

          base_name ||= begin
            name = base.name || "Resource"
            name.split( "::" )
                .last
                .sub( /Entity/, "" )
                .gsub( /(.)([[:upper:]])/, '\1 \2' )
          end
          base.attribute attr, default: "Unknown #{ base_name }"
        end
      end

      # Dynamically generate a new null entity class.
      # @param [Class] entity_class {Entity} class
      # @return [Class] a null entity class derived from `entity_class`.
      def self.for( entity_class )
        if null_klass = ( entity_class.const_defined?( :NullEntity ) && entity_class.const_get( :NullEntity, false ) )
          # If the base class is reloaded a-la rails dev, then regenerate the
          # null class as well.
          null_klass = nil if null_klass.superclass != entity_class
        end

        unless null_klass
          null_klass = Class.new( entity_class ) do
            include ::Shamu::Entities::NullEntity
          end

          entity_class.const_set :NullEntity, null_klass
        end

        null_klass
      end

    end
  end
end