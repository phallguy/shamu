require "spec_helper"
require "shamu/entities"

module EntityListSpec
  class Entity < Shamu::Entities::Entity
    attribute :id
    attribute :label
  end
end

describe Shamu::Entities::List do
  let( :first )  { EntityListSpec::Entity.new id: 1, label: :one }
  let( :second ) { EntityListSpec::Entity.new id: 2, label: :two }
  let( :source ) { [ first, second ] }

  let( :list ) do
    Shamu::Entities::List.new( source )
  end

  describe "#each" do
    it "is lazy" do
      raw = [ first, second ]
      expect( raw ).to receive( :lazy )

      list = Shamu::Entities::List.new( raw )
      list.to_a
    end

    it "enumerates over the entities" do
      expect do |b|
        list.each( &b )
      end.to yield_control.twice
    end
  end

  describe "#get" do
    it "finds by id by default" do
      expect( list.get( 1 ) ).to be first
    end

    it "finds by custom pk" do
      expect( list.get( :two, field: :label ) ).to be second
    end

    it "raises when not found" do
      expect do
        list.get( 42 )
      end.to raise_error Shamu::NotFoundError
    end
  end

  describe "short-circuits" do
    [ :first, :count, :empty? ].each do |method|
      it "delegates #{ method } to entities" do
        expect( source ).to receive( method ).and_call_original
        list.send( method )
      end
    end
  end
end