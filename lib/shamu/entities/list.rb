module Shamu
  module Entities
    # A list of {Entities::Entity} records.
    class List
      include Enumerable

      # @param [Enumerable] entities the raw list of entities.
      def initialize(entities)
        raise(ArgumentError, "missing entities") if entities.nil?

        @raw_entities = entities
      end

      # Enumerate through each of the entities in the list.
      def each(&block)
        if eager?
          entities.to_a.each(&block)
        else
          entities.each(&block)
        end
      end

      delegate :first, :last, :[], :empty?, to: :raw_entities

      alias size count
      alias length count

      def count
        eager? ? to_a.count : raw_entities.count
      end

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
      def get(key, field: key_attribute)
        entity =
          if field == :id
            key = key.to_model_id
            entities.find { |e| e.id == key }
          else
            entities.find { |e| e.send(field) == key }
          end
        entity || raise(Shamu::NotFoundError)
      end

      def inspect
        if @entities
          format("#<%s: {%s}>", self.class.name, to_a.inspect)
        else
          format("#<%s: ...>", self.class.name)
        end
      end

      def pretty_print(pp)
        if @entities
          pp.text(format("#<%s: {", self.class.name))
          pp.nest(1) do
            pp.seplist(self) { |o| pp.pp(o) }
          end
          pp.text("}>")
        else
          pp.text(format("#<%s: ...>", self.class.name))
        end
      end

      def to_a
        entities.to_a
      end

      def to_ary
        entities.to_a
      end

      # Eagerly load the list into memory before attempting to count the
      # entities or enumerate over them.
      #
      # @return [Self]
      def eager!
        @eager = true
        self
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

        def eager?
          @eager
        end
    end
  end
end
