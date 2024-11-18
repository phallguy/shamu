module Shamu
  module Entities
    # Implements an in-memory store of entities for static entities (rich enum
    # types) offering standard read methods #find, #lookup and #list.
    class StaticRepository
      def initialize(entities, missing_entity_class: nil)
        raise ArgumentError, :entities if entities.map(&:id).count != entities.map(&:id).uniq.count

        entities = entities.dup.freeze unless entities.frozen?

        @entities             = entities
        @missing_entity_class = missing_entity_class || NullEntity.for(entities.first.class)
        @lookup_cache         = {}
      end

      # Find an entity with the given value on the named attribute.
      #
      # @param [Object] value to look for.
      # @param [Symbol] attribute to interrogate.
      # @return [Entity] the entity if found.
      # @raise [Shamu::NotFoundError] if the entity could not be found.
      def find_by(attribute, value)
        cache = attribute_cache(attribute)
        cache.fetch(value) do
          cache[value] = find_by_attribute(attribute, value)
        end
      end

      # Find an entity with the given id.
      #
      # @return [Entity] the entity if found.
      # @raise [Shamu::NotFoundError] if the entity could not be found.
      def find(id = :not_set)
        raise ArgumentError, :id if id == :not_set && !block_given?

        value = block_given? ? yield : find_by(:id, id)
        value || not_found!
      end

      # Lookup all the entities in the repository with the given ids.
      # @param [Array<Integer>] ids
      # @return [List<Entity>] the matching entities.
      def lookup(*ids)
        cache = attribute_cache(:id)
        matching = ids.map do |id|
          entity = cache.fetch(id) do
            entities.find { |e| e.id == id }
          end

          entity || missing_entity_class.new
        end

        List.new(matching)
      end

      # @return [List<Entity>] all the entities in the repository.
      def list
        List.new(entities)
      end

      private

        attr_reader :entities, :missing_entity_class

        def not_found!
          raise Shamu::NotFoundError
        end

        def attribute_cache(attribute)
          @lookup_cache.fetch(attribute) do
            @lookup_cache[attribute] = {}
          end
        end

        def find_by_attribute(attribute, value)
          entities.find { |e| e.send(attribute) == value } || not_found!
        end
    end
  end
end
