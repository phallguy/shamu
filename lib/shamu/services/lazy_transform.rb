module Shamu
  module Services

    # Lazily transform one enumerable to another with shortcuts for common
    # collection methods such as first, count, etc.
    class LazyTransform
      include Enumerable

      # @param [Enumerable] source enumerable to transform.
      # @yieldparam [Object] object the original value.
      # @yieldreturn the transformed value.
      # @yield (object)
      def initialize( source, &transformer )
        @transformer = transformer
        @source      = source
      end

      # Yields each transformed value from the original source to the block.
      #
      # @yield (object)
      # @yieldparam [Object] object
      # @return [self]
      def each( &block )
        transformed.each( &block )
        self
      end

      # (see Enumerable#count)
      # @return [Integer]
      def count( *args )
        if args.any? || block_given?
          super
        else
          source.count
        end
      end
      alias_method :size, :count
      alias_method :length, :count

      # Get the first transformed value without transforming the entire list.
      # @overload first(n)
      # @overload first
      # @return [Object]
      def first( *args )
        if args.any?
          super
        else
          return @first if defined? @first
          @first = begin
            value = source.first
            transformer.call( value ) unless value.nil?
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
      def take( n )
        if transformed?
          super
        else
          self.class.new( source.take( n ), &transformer )
        end
      end

      # @param [Integer] n number of source entries to skip.
      # @return [LazyTransform] a new {LazyTransform} skipping `n` source
      #     entries.
      def drop( n )
        if transformed?
          super
        else
          self.class.new( source.drop( n ), &transformer )
        end
      end

      private

        attr_reader :source
        attr_reader :transformer

        def transformed
          @transformed ||= source.map( &transformer )
        end

        def transformed?
          !!@transformed
        end
    end
  end
end
