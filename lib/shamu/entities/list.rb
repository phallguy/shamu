module Shamu
  module Entities

    # A list of {Entities::Entity} records.
    class List
      include Enumerable

      # @param [Enumerable] entities the raw list of entities.
      def initialize( entities )
        fail ArgumentError, "missing entities" if entities.nil?
        @raw_entities = entities
      end

      # Enumerate through each of the entities in the list.
      def each( &block )
        entities.each( &block )
      end

      delegate :first, :last, :count, :empty?, :index, to: :raw_entities

      alias_method :size, :count
      alias_method :length, :count

      # @return [Boolean] true if the list represents a slice of a larger set.
      # See {PagedList} for paged implementation.
      def paged?
        false
      end

      # Get an entity by it's primary key.
      # @param [Object] key the primary key to look for.
      # @param [Symbol] field to use as the primary key. Default :id.
      # @return [Entities::Entity] the found entity.
      # @raise [Shamu::NotFoundError] if the entity cannot be found.
      def get( key, field: key_attribute )
        entity =
          if field == :id
            entities.find { |e| e.id == key }
          else
            entities.find { |e| e.send( field ) == key }
          end
        entity || fail( Shamu::NotFoundError )
      end

      private

        attr_reader :raw_entities

        def entities
          # Array and others do not implement #lazy so allow anything that
          # doesn't support lazy to just enumerate directly.
          @entities ||= raw_entities.lazy || raw_entities
        end

        def key_attribute
          :id
        end
    end
  end
end
