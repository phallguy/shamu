require "shamu/entities/active_model"

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

      def self.extended( base )
        base.include Shamu::Entities::ActiveModel
      end


      # Apply the filters defined in a {ListScope} to an ActiveRecord::Relation.
      #
      # @param [ListScope] scope to apply
      # @return [ActiveRecord::Relation]
      def by_list_scope( scope )
        criteria = all
        criteria = apply_custom_list_scope( criteria, scope )
        criteria = apply_paging_scope( criteria, scope )        if scope.respond_to?( :paged? )
        criteria = apply_scoped_paging_scope( criteria, scope ) if scope.respond_to?( :scoped_page? )
        criteria = apply_dates_scope( criteria, scope )         if scope.respond_to?( :dated? )
        criteria = apply_sorting_scope( criteria, scope )       if scope.respond_to?( :sorted? )
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
        def apply_sort( criteria, field, direction )
          if attribute_method?( field )
            criteria.order( arel_table[ field ].send direction )
          else
            criteria
          end
        end

        def apply_sorting_scope( criteria, scope )
          if scope.sort_by
            criteria = scope.sort_by.reduce( criteria ) do |criteria, ( field, direction )|
              apply_sort( criteria, field, direction )
            end
          end

          criteria
        end

        def apply_paging_scope( criteria, scope )
          if scope.paged?
            criteria = criteria.page( scope.page || 1 )
            criteria = criteria.per( scope.per_page ) if scope.per_page
          end
          criteria
        end

        def apply_scoped_paging_scope( criteria, scope )
          if scope.scoped_page?
            criteria = criteria.page( scope.page.number || 1 )
            criteria = criteria.per( scope.page.size ) if scope.page.size
          end
          criteria
        end

        def apply_dates_scope( criteria, scope )
          criteria = criteria.where( criteria.arel_table[:since].gteq scope.since ) if scope.since
          criteria = criteria.where( criteria.arel_table[:until].lteq scope.until ) if scope.until
          criteria
        end

        def apply_custom_list_scope( criteria, scope )
          custom_list_scope_attributes( scope ).each do |name|
            scope_name = :"by_#{ name }"
            if criteria.respond_to?( scope_name )
              value    = scope.send( name )
              criteria = criteria.send scope_name, value if value.present?
            else
              fail ArgumentError, "Cannot apply '#{ name }' filter from #{ scope.class.name }. Add 'scope :#{ scope_name }, ->( #{ name } ) { ... }' to #{ criteria.class.name }"
            end
          end

          criteria
        end

        def custom_list_scope_attributes( scope )
          scope.class.attributes.keys - StandardListScopeTemplate.attributes.keys
        end

        class StandardListScopeTemplate < ListScope
          include ListScope::Paging
          include ListScope::ScopedPaging
          include ListScope::Dates
          include ListScope::Sorting
        end

    end
  end
end