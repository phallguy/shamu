module Shamu
  module Security


    # Redacts entities in a list when they are materialized for the first time
    class RedactedList < Shamu::Entities::List

      # @param [Entities::List] list to be redacted
      # @yield (list)
      # @yieldreturn [Enumerable<Entities::Entity>] the redacted entities.
      def initialize( list, &redactor )
        @redactor = redactor
        @list = list

        super( list )
      end

      def first
        entity = super
        entity && redactor.call([ entity ]).first
      end

      def last
        entity = super
        entity && redactor.call([ entity ]).first
      end

      # Make sure redacted lists can delegate to paged lists.
      delegate :empty?, :total_count, :limit, :offset, :current_page, :to_a, :to_ary,
               :paged?, :next?, :last?, :first?, :previous?,
               to: :list

      private

        attr_reader :list
        attr_reader :redactor

        def entities
          @entities ||= redactor.call( super )
        end
    end
  end
end
