module Shamu
  module Entities

    # A list of {Entities::Entity} records.
    class PagedList < List
      include Enumerable

      # @param [Enumerable] entities the raw list of entities.
      # @param [Integer, #call] total_count the number (or a proc that resolves
      # to a number) of records in the entire set.
      # @param [Integer, #call] limit the maximum number (or a proc that resolves to a
      # number) of records in the page represented by the list.
      # @param [Integer, #call] offset the number (or a proc that resolves to a
      # number) offset from the start of the set that this list represents.
      # @param [Boolean,#call] has_next true if there is another page
      # available or a proc that returns a bool.
      # @param [Boolean,#call] has_previous true if there is a previous page
      # available or a proc that returns a bool.
      def initialize( entities,
                      total_count: :not_set,
                      limit: :not_set,
                      offset: :not_set,
                      has_next: :not_set,
                      has_previous: :not_set )
        super( entities )

        @total_count  = total_count
        @limit        = limit
        @offset       = offset
        @has_next     = has_next
        @has_previous = has_previous
      end

      # (see List#paged?)
      def paged?
        true
      end

      # @return [Integer] the total number of records in the set.
      def total_count
        if @total_count == :not_set
          raw_entities.total_count
        elsif @total_count.respond_to?( :call )
          @total_count = @total_count.call
        else
          @total_count
        end
      end

      # @return [Integer] the maximum number of records to return in each page.
      def limit
        if @limit == :not_set
          if raw_entities.respond_to?( :limit_value )
            raw_entities.limit_value
          elsif raw_entities.respond_to?( :limit )
            raw_entities.limit
          end
        elsif @limit.respond_to?( :call )
          @limit = @limit.call
        else
          @limit
        end
      end
      alias_method :per_page, :limit

      # @return [Integer] the absolute offset into the set for the window of
      # data that that this list contains.
      def offset
        if @offset == :not_set
          if raw_entities.respond_to?( :offset_value )
            raw_entities.offset_value
          elsif raw_entities.respond_to?( :offset )
            raw_entities.offset
          end
        elsif @offset.respond_to?( :call )
          @offset = @offset.call
        else
          @offset
        end
      end

      # @return [Integer] the current page number.
      def current_page
        if limit > 0
          ( offset / limit ).to_i + 1
        else
          1
        end
      end

      # @return [Boolean] true if there is another page of data available.
      def next? # rubocop:disable Metrics/PerceivedComplexity
        if @has_next == :not_set
          if raw_entities.respond_to?( :has_next? )
            raw_entities.has_next?
          elsif raw_entities.respond_to?( :next_page )
            !!raw_entities.next_page
          elsif raw_entities.respond_to?( :last_page? )
            !raw_entities.last_page?
          end
        elsif @has_next.respond_to?( :call )
          @has_next = @has_next.call
        else
          @has_next
        end
      end
      alias_method :has_next?, :next?

      # @return [Boolean] true if this list represents the last page in the
      # set.
      def last?
        !next?
      end

      # @return [Boolean] true if there is another page of data available.
      def previous? # rubocop:disable Metrics/PerceivedComplexity
        if @has_previous == :not_set
          if raw_entities.respond_to?( :has_previous? )
            raw_entities.has_previous?
          elsif raw_entities.respond_to?( :prev_page )
            !!raw_entities.prev_page
          elsif raw_entities.respond_to?( :first_page? )
            !raw_entities.first_page?
          end
        elsif @has_previous.respond_to?( :call )
          @has_previous = @has_previous.call
        else
          @has_previous
        end
      end
      alias_method :has_prev?, :previous?
      alias_method :has_previous, :previous?

      # @return [Boolean] true if this list represents the first page in the
      # set.
      def first?
        !previous?
      end
    end
  end
end
