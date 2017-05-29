require "spec_helper"
require "active_record"
require "lib/shamu/active_record_support"

module PagedListSpec
  class Scope < ::ActiveRecordSpec::FavoriteScope
    include Shamu::Entities::ListScope::Paging
  end
end

describe Shamu::Entities::PagedList do
  use_active_record

  let( :relation ) do
    scope = PagedListSpec::Scope.new( per_page: 10 )
    ActiveRecordSpec::Favorite.by_list_scope( scope )
  end

  let( :transform ) do
    Shamu::Services::LazyTransform.new( relation ) do |records|
      records.map do |record|
        ActiveRecordSpec::FavoriteEntity.new( record: record )
      end
    end
  end

  describe "#total_count" do
    it "delegates to underlying relation" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :total_count )
      list.total_count
    end

    it "uses absolute value" do
      list = Shamu::Entities::PagedList.new( transform, total_count: 23 )

      expect( list.total_count ).to eq 23
    end

    it "invokes block" do
      expect do |b|
        list = Shamu::Entities::PagedList.new( transform, total_count: b.to_proc )
        list.total_count
      end.to yield_control
    end
  end

  describe "#limit" do

    it "delegates to underlying relation" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :limit_value )
      list.limit
    end

    it "uses absolute value" do
      list = Shamu::Entities::PagedList.new( transform, limit: 23 )

      expect( list.limit ).to eq 23
    end

    it "invokes block" do
      expect do |b|
        list = Shamu::Entities::PagedList.new( transform, limit: b.to_proc )
        list.limit
      end.to yield_control
    end

  end

  describe "#offset" do

    it "delegates to underlying relation" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :offset_value )
      list.offset
    end

    it "uses absolute value" do
      list = Shamu::Entities::PagedList.new( transform, offset: 23 )

      expect( list.offset ).to eq 23
    end

    it "invokes block" do
      expect do |b|
        list = Shamu::Entities::PagedList.new( transform, offset: b.to_proc )
        list.offset
      end.to yield_control
    end

  end

  describe "#next?" do

    it "delegates to underlying relation has_next?" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :has_next? )
      list.next?
    end

    it "delegates to underlying relation last_page?" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :last_page? )
      list.next?
    end

    it "uses absolute value" do
      list = Shamu::Entities::PagedList.new( transform, has_next: true )

      expect( list.next? ).to be_truthy
    end

    it "invokes block" do
      expect do |b|
        list = Shamu::Entities::PagedList.new( transform, has_next: b.to_proc )
        list.next?
      end.to yield_control
    end

  end

  describe "#previous?" do

    it "delegates to underlying relation has_previous?" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :has_previous? )
      list.previous?
    end

    it "delegates to underlying relation last_page?" do
      list = Shamu::Entities::PagedList.new( transform )

      expect( relation ).to receive( :first_page? )
      list.previous?
    end

    it "uses absolute value" do
      list = Shamu::Entities::PagedList.new( transform, has_previous: true )

      expect( list.previous? ).to be_truthy
    end

    it "invokes block" do
      expect do |b|
        list = Shamu::Entities::PagedList.new( transform, has_previous: b.to_proc )
        list.previous?
      end.to yield_control
    end

  end

  describe "current_page" do
    it "calculates page" do
      list = Shamu::Entities::PagedList.new( transform, limit: 5, offset: 15 )
      expect( list.current_page ).to eq 4
    end

    it "calculates page with padding" do
      list = Shamu::Entities::PagedList.new( transform, limit: 5, offset: 16 )
      expect( list.current_page ).to eq 4
    end
  end
end
