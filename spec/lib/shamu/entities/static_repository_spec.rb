require "spec_helper"

module StaticRepositorySpec
  class Entity < Shamu::Entities::Entity
    attribute :id
    attribute :name
  end
end

describe Shamu::Entities::StaticRepository do
  let( :entities ) do
    [
      scorpion.fetch( StaticRepositorySpec::Entity, { id: 10, name: "First" }, {} ),
      scorpion.fetch( StaticRepositorySpec::Entity, { id: 20, name: "Last" }, {} ),
    ]
  end
  let( :repository ) do
    Shamu::Entities::StaticRepository.new entities
  end

  it "does not allow duplicate keys" do
    expect do
      Shamu::Entities::StaticRepository.new [
        StaticRepositorySpec::Entity.new( id: 1 ),
        StaticRepositorySpec::Entity.new( id: 1 ),
      ]
    end.to raise_exception ArgumentError
  end

  it "requires at least one entity" do
    expect do
      Shamu::Entities::StaticRepository.new
    end.to raise_exception ArgumentError
  end

  describe "#find" do
    it "finds by id" do
      expect( repository.find( 10 ) ).to be entities.first
    end

    it "raises when not found" do
      expect do
        repository.find( 0 )
      end.to raise_exception Shamu::NotFoundError
    end

    it "yields to block" do
      expect do |b|
        repository.find do
          b.to_proc.call
          true
        end
      end.to yield_control
    end

    it "raises if no argument and no block" do
      expect do
        repository.find
      end.to raise_exception ArgumentError
    end

    it "raises when not found by block" do
      expect do
        repository.find { false }
      end.to raise_exception Shamu::NotFoundError
    end
  end

  describe "#find_by" do
    it "finds by id" do
      expect( repository.find_by( :id, 10 ) ).to be entities.first
    end

    it "raises when not found" do
      expect do
        repository.find_by :id, 0
      end.to raise_exception Shamu::NotFoundError
    end

    it "caches lookup" do
      expect( repository ).to receive( :find_by_attribute ).and_call_original
      repository.find_by :id, 10

      expect( repository ).not_to receive( :find_by_attribute )
      repository.find_by :id, 10
    end

    it "finds by name" do
      expect( repository.find_by( :name, "Last" ) ).to be entities.last
    end

    it "caches lookup by name" do
      expect( repository ).to receive( :find_by_attribute ).and_call_original
      repository.find_by( :name, "First" )

      expect( repository ).not_to receive( :find_by_attribute )
      repository.find_by( :name, "First" )
    end
  end

  describe "#lookup" do
    it "finds all ids" do
      list = repository.lookup 10, 20
      expect( list.to_a ).to eq entities
    end

    it "uses missing entity if not found" do
      list = repository.lookup 20, 30

      expect( list.first ).to be entities.last
      expect( list.last ).not_to be_present
    end

    it "returns an Entities::List" do
      expect( repository.lookup ).to be_a Shamu::Entities::List
    end
  end

  describe "#list" do
    it "lists all records" do
      expect( repository.list.to_a ).to eq entities
    end

    it "returns an Entities::List" do
      expect( repository.list ).to be_a Shamu::Entities::List
    end
  end

end
