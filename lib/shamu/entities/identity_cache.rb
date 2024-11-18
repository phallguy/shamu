module Shamu
  module Entities
    # Keeps a cache of {Entity} instances in memory for quick retrieval. Since
    # entities are immutable, the cache
    class IdentityCache
      # Provide a block to automatically coerce keys to a known type. For
      # example converting numeric strings ("123") to Integer values.
      #
      # @param [Symbol] coercion method to call on keys instead of providing a
      #     block.
      # @yield (key)
      # @yieldparam [Object] key to coerce
      # @yieldreturn [Object] the coerced value of the key.
      def initialize(coercion = nil, &coercion_block)
        @cache = {}
        @coercion = block_given? ? coercion_block : (coercion && coercion.to_proc)
      end

      # Fetch an entity with the given key.
      # @param [Object] key of the entity. Typically the {Entity#id}.
      # @return [Entity] the entity if found, otherwise `nil`.
      def fetch(key)
        cache.fetch(coerce_key(key), nil)
      end

      # Filter the list of `keys` to those that haven't been cached yet.
      # @param [Array] keys of the {Entity entities} that are about to be
      #     {#fetch fetched}.
      # @return [Array] the uncached keys.
      def uncached_keys(keys)
        uncached = Array(keys).map { |k| coerce_key(k) }
        uncached.reject! { |k| cache.key?(k) }
        uncached
      end

      # Add a new entity to the cache.
      # @param [Object] key of the entity. Typically the {Entity#id}.
      # @param [Entity] entity to cache
      # @return [entity]
      def add(key, entity)
        cache[coerce_key(key)] = entity
      end

      # Invalidate the cached entry for the {Entity} with the given `key`.
      # @param [Object] key of the entity. Typically the {Entity#id}.
      # @return [Entity] the entity that was at the given key if present.
      def invalidate(key)
        cache.delete(key)
      end

      private

        attr_reader :cache
        attr_reader :coercion

        def coerce_key(key)
          return key unless coercion

          coercion.call(key)
        end
    end
  end
end