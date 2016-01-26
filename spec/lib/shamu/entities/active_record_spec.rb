require "spec_helper"
require "shamu/entities/active_record"
require "active_record"


module EntitiesActiveRecordSpec
  class Model < ActiveRecord::Base
    self.table_name = "entities_active_record_models"
    extend Shamu::Entities::ActiveRecord

    scope :by_name, ->( name ) { where( name: name ) }
  end

  class Migration < ActiveRecord::Migration
    def self.up
      create_table :entities_active_record_models do |t|
        t.string :name
      end
    end

    def self.down
      drop_table :entities_active_record_models
    end
  end

  class Scope < Shamu::Entities::ListScope
    attribute :name
  end
end

describe Shamu::Entities::ActiveRecord do
  describe ".by_list_scope" do
    before do
      EntitiesActiveRecordSpec::Migration.verbose = false
      EntitiesActiveRecordSpec::Migration.up
    end

    after do
      EntitiesActiveRecordSpec::Migration.down
    end

    it "filters by attribute" do
      scope    = EntitiesActiveRecordSpec::Scope.new( name: "example" )
      relation = EntitiesActiveRecordSpec::Model.by_list_scope( scope )

      expect( relation.where_values_hash ).to have_key "name"
    end

    it "filters by paging" do
      klass = Class.new( EntitiesActiveRecordSpec::Scope ) do
        include Shamu::Entities::ListScope::Paging
      end

      scope    = klass.new( page: 1, page_size: 25 )
      relation = EntitiesActiveRecordSpec::Model.by_list_scope( scope )

      expect( relation.offset_value ).to eq 0
      expect( relation.limit_value ).to eq 25
    end

    it "filters by scoped paging" do
      klass = Class.new( EntitiesActiveRecordSpec::Scope ) do
        include Shamu::Entities::ListScope::ScopedPaging
      end

      scope    = klass.new( page: { number: 1, size: 25 } )
      relation = EntitiesActiveRecordSpec::Model.by_list_scope( scope )

      expect( relation.offset_value ).to eq 0
      expect( relation.limit_value ).to eq 25
    end

    it "filters by dates" do
      klass = Class.new( EntitiesActiveRecordSpec::Scope ) do
        include Shamu::Entities::ListScope::Dates
      end

      since_date = Time.at( 50_000 )
      until_date = Time.at( 60_000 )

      scope    = klass.new( since: since_date, until: until_date )
      relation = EntitiesActiveRecordSpec::Model.by_list_scope( scope )

      expect( relation.where_values.any? { |w| w.left.name == :since } ).to be_truthy
      expect( relation.where_values.any? { |w| w.left.name == :until } ).to be_truthy
    end

    it "sorts by attribute" do
      klass = Class.new( EntitiesActiveRecordSpec::Scope ) do
        include Shamu::Entities::ListScope::Sorting
      end

      scope    = klass.new( sort_by: :name )
      relation = EntitiesActiveRecordSpec::Model.by_list_scope( scope )

      expect( relation.order_values.any? { |o| o.expr.name == :name } ).to be_truthy
    end
  end
end