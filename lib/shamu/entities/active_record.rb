module Shamu
  module Entities
    # Mixins for working with ActiveRecord resources as {Entity entities}.
    #
    # ```
    # module Domain
    #   module Models
    #     class Account < ActiveRecord::Base
    #       extend Shamu::Entities::ActiveRecord
    #     end
    #   end
    #
    #   class AccountListScope < Shamu::Entities::ListScope
    #     attribute :name
    #   end
    # end
    #
    # list_scope = Domain::AccountListScope.new( name: "Flipper" )
    # records = Domain::Models::Account.all.by_list_scope( list_scope )
    # ```
    module ActiveRecord
      extend ActiveSupport::Concern

      def entity_class
        self.class.entity_class
      end

      def service_class
        self.class.service_class
      end

      class_methods do
        def entity_class
          @entity_class ||= "#{model_name.name.sub('::Models', '')}Entity".constantize
        end

        def service_class
          entity_class.service_class
        end

        # Apply the filters defined in a {ListScope} to an ActiveRecord::Relation.
        #
        # @param [ListScope] scope to apply
        # @return [ActiveRecord::Relation]
        def by_list_scope(scope)
          raise ::Shamu::Entities::ListScopeInvalidError unless scope.valid?

          criteria = all
          criteria = apply_paging_scope(criteria, scope)        if scope.respond_to?(:paged?)
          criteria = apply_scoped_paging_scope(criteria, scope) if scope.respond_to?(:scoped_page?)
          criteria = apply_window_paging_scope(criteria, scope) if scope.respond_to?(:window_paged?)
          criteria = apply_dates_scope(criteria, scope)         if scope.respond_to?(:dated?)
          criteria = apply_sorting_scope(criteria, scope)       if scope.respond_to?(:sorted?)
          criteria = apply_custom_list_scope(criteria, scope)
          criteria
        end

        #
        # @!endgroup Scopes

        private

          # @!visibility public
          #
          # Apply sorting to the criteria for the given field and the given
          # direction.
          #
          # @param [ActiveRecord::Relation] criteria to sort.
          # @param [Symbol] field to sort by.
          # @param [Symbol] direction to sort.
          # @return [ActiveRecord::Relation] the sorted criteria.
          def apply_sort(criteria, field, direction)
            if attribute_method?(field)
              criteria.order(arel_table[field].send(direction))
            else
              criteria
            end
          end

          def apply_sorting_scope(criteria, scope)
            if scope.sort_by
              criteria = scope.sort_by_resolved.reduce(criteria) do |crit, (field, direction)|
                apply_sort(crit, field, direction)
              end
            end

            criteria
          end

          def apply_paging_scope(criteria, scope)
            if scope.paged?
              criteria = criteria.page(scope.page || 1)
              criteria = criteria.per(scope.per_page) if scope.per_page
            end
            criteria
          end

          def apply_scoped_paging_scope(criteria, scope)
            if scope.scoped_page?
              criteria = criteria.page(scope.page.number || 1)
              criteria = criteria.per(scope.page.size) if scope.page.size
            end
            criteria
          end

          def apply_window_paging_scope(criteria, scope)
            if scope.window_paged?
              criteria = criteria.page(1)
              criteria = criteria.per(scope.first)     if scope.first
              criteria = criteria.offset(scope.after)  if scope.after
              criteria = criteria.per(scope.last)      if scope.last
              criteria = criteria.offset(scope.before) if scope.before
            end

            criteria
          end

          def apply_dates_scope(criteria, scope)
            criteria = criteria.where(criteria.arel_table[:since].gteq(scope.since)) if scope.since
            criteria = criteria.where(criteria.arel_table[:until].lteq(scope.until)) if scope.until
            criteria
          end

          def apply_custom_list_scope(criteria, scope)
            custom_list_scope_attributes(scope).each do |name|
              next unless scope.assigned?(name)

              scope_name = :"by_#{name}"
              apply_name = :"apply_#{name}_list_scope"

              if criteria.respond_to?(scope_name)
                value    = scope.send(name)
                criteria = criteria.send(scope_name, value) if value.present?
              elsif criteria.respond_to?(apply_name)
                criteria = criteria.send(apply_name, criteria, scope)
              elsif criteria.table[name]
                value    = scope.send(name)
                criteria = criteria.where(name => value)
              else
                raise(ArgumentError, "Cannot apply '#{name}' filter from #{scope.class.name}. Add 'scope :#{scope_name}, ->( #{name} ) { ... }' or 'def self.#{apply_name}( criteria, scope )' to #{self.name}")
              end
            end

            criteria
          end

          def custom_list_scope_attributes(scope)
            scope.class.attributes.keys - StandardListScopeTemplate.attributes.keys
          end
      end

      # @!visibility private
      # @api internal
      class StandardListScopeTemplate < ListScope
        include ListScope::Paging
        include ListScope::ScopedPaging
        include ListScope::WindowPaging
        include ListScope::Dates
        include ListScope::Sorting
      end
    end
  end
end
