require "spec_helper"

describe Shamu::Entities::IdentityCache do
  let( :klass ) do
    Class.new( Shamu::Entities::Entity ) do
      attribute :id
      attribute :name
    end
  end

  let( :cache )  { scorpion.new( Shamu::Entities::IdentityCache, :to_i ) }
  let( :entity ) { klass.new id: 89, name: "Sparkles" }

  describe "#fetch" do
    before( :each ) do
      cache.add( entity.id, entity )
    end

    it "fetches id by Number" do
      expect( cache.fetch( entity.id ) ).to be entity
    end

    it "fetches id by String" do
      expect( cache.fetch( entity.id.to_s ) ).to be entity
    end
  end

  describe "#uncached_keys" do
    before( :each ) do
      cache.add( entity.id, entity )
    end

    it "includes keys that have not been cached" do
      expect( cache.uncached_keys( [ 90 ] ) ).to eq [ 90 ]
    end

    it "includes coerced keys that have not been cached" do
      expect( cache.uncached_keys( [ "100" ] ) ).to eq [ 100 ]
    end

    it "excludes numeric keys that have already been cached" do
      expect( cache.uncached_keys( [ 88, 89 ] ) ).to eq [ 88 ]
    end

    it "excludes string keys that have already been cached" do
      expect( cache.uncached_keys( [ "88", "89" ] ) ).to eq [ 88 ]
    end
  end

  describe "#add" do
    it "adds entity to cache" do
      cache.add( entity.id, entity )
      expect( cache.fetch( entity.id ) ).to be entity
    end

    it "returns the entity" do
      expect( cache.add( entity.id, entity ) ).to be entity
    end
  end

  describe "#invalidate" do
    it "removes entity from cache" do
      cache.add( entity.id, entity )
      cache.invalidate( entity.id )

      expect( cache.fetch( entity.id ) ).to be_blank
    end
  end
end