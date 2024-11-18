require "spec_helper"
require "active_record"
require "shamu/entities/active_record"
require "shamu/entities/active_record_soft_destroy"

describe Shamu::Entities::ActiveRecord do
  use_active_record

  describe ".by_list_scope" do
    it "filters by attribute" do
      scope    = ActiveRecordSpec::FavoriteScope.new(name: "example")
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.where_values_hash).to(have_key("name"))
    end

    it "filters by paging" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::Paging
      end

      scope    = klass.new(page: 1, page_size: 25)
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.offset_value).to(eq(0))
      expect(relation.limit_value).to(eq(25))
    end

    it "filters by scoped paging" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::ScopedPaging
      end

      scope    = klass.new(page: { number: 1, size: 25 })
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.offset_value).to(eq(0))
      expect(relation.limit_value).to(eq(25))
    end

    it "filters by window paging" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::WindowPaging
      end

      scope    = klass.new(first: 10, after: 30)
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.offset_value).to(eq(30))
      expect(relation.limit_value).to(eq(10))
    end

    it "filters by inverse window paging" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::WindowPaging
      end

      scope = klass.new
      expect(scope).to(receive(:reverse_sort!).at_least(:once))
      scope.assign_attributes(last: 10, before: 30)
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.offset_value).to(eq(30))
      expect(relation.limit_value).to(eq(10))
    end

    it "filters by dates" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::Dates
      end

      since_date = Time.at(50_000)
      until_date = Time.at(60_000)

      scope    = klass.new(since: since_date, until: until_date)
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.where_clause.any? { |w| w.left.name == "since" }).to(be_truthy)
      expect(relation.where_clause.any? { |w| w.left.name == "until" }).to(be_truthy)
    end

    it "sorts by attribute" do
      klass = Class.new(ActiveRecordSpec::FavoriteScope) do
        include Shamu::Entities::ListScope::Sorting
      end

      scope    = klass.new(sort_by: :name)
      relation = ActiveRecordSpec::Favorite.by_list_scope(scope)

      expect(relation.order_values.any? { |o| o.expr.name == "name" }).to(be_truthy)
    end
  end
end
