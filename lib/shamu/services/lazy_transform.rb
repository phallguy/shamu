module Shamu
  module Services
    # Lazily transform one enumerable to another with shortcuts for common
    # collection methods such as first, count, etc.
    class LazyTransform
      include Enumerable

      # @param [Enumerable] source enumerable to transform.
      # @yieldparam [Array<Object>] objects the original values.
      # @yieldreturn the transformed values.
      # @yield (object)
      def initialize(source, &transformer)
        @transformer = transformer
        @source      = source
      end

      # Yields each transformed value from the original source to the block.
      #
      # @yield (object)
      # @yieldparam [Object] object
      # @return [self]
      def each(&block)
        transformed.each(&block)
        self
      end

      # Transforms the source and returns the full results as an array.
      # @return [Array]
      def to_a
        transformed.to_a
      end

      # @attribute [Integer] index
      # @return [Object] the transformed object at the given index.
      def [](index)
        transformed[index]
      end

      # (see Enumerable#count)
      # @return [Integer]
      def count(*args)
        if args.any? || block_given?
          super
        else
          source.count
        end
      end
      alias size count
      alias length count

      # Get the first transformed value without transforming the entire list.
      # @overload first(n)
      # @overload first
      # @return [Object]
      def first(*args)
        if args.any?
          super
        else
          return @first if defined? @first

          @first = begin
            value = source.first
            raise_if_not_transformed(transformer.call([value])).first unless value.nil?
          end
        end
      end

      # Get the last transformed value without transforming the entire list.
      # @overload last(n)
      # @overload last
      # @return [Object]
      def last(*args)
        if args.any?
          transformed.last(*args)
        else
          return @last if defined? @last

          @last = begin
            value = source.last
            raise_if_not_transformed(transformer.call([value])).last unless value.nil?
          end
        end
      end

      # @return [Boolean] true if there are no source values.
      def empty?
        source.empty?
      end

      # @param [Integer] n number of source entries to take.
      # @return [LazyTransform] a new {LazyTransform} taking only `n` source
      #     entries.
      def take(n)
        if transformed?
          super
        else
          self.class.new(source.take(n), &transformer)
        end
      end

      # @param [Integer] n number of source entries to skip.
      # @return [LazyTransform] a new {LazyTransform} skipping `n` source
      #     entries.
      def drop(n)
        if transformed?
          super
        else
          self.class.new(source.drop(n), &transformer)
        end
      end

      # For all other methods, force a transform then delegate to the
      # transformed list.

      def method_missing(name, *args, &block)
        if respond_to_missing?(name, false)
          source.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(*args)
        super || source.respond_to?(*args)
      end

      private

        attr_reader :source
        attr_reader :transformer

        def transformed
          @transformed ||= raise_if_not_transformed(transformer.call(source))
        end

        def transformed?
          !!@transformed
        end

        def raise_if_not_transformed(transformed)
          raise "Block to LazyTransform did not return an enumerable value" unless transformed.is_a?(Enumerable)

          transformed
        end
    end
  end
end
