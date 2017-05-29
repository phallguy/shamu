require "spec_helper"
require_relative "entity_lookup_models"

describe Shamu::Entities::OpaqueEntityLookupService do
  let( :service ) { scorpion.new Shamu::Entities::OpaqueEntityLookupService }

  describe "#ids" do
    it "obfuscates the ids" do
      entity = EntityLookupServiceSpecs::ExampleEntity.new( id: 5 )
      expect( service.ids( entity ) ).not_to include( match( /EntityLookupServiceSpecs/ ) )
    end
  end

  describe "#record_ids" do
    it "gets the original record id" do
      entity = EntityLookupServiceSpecs::ExampleEntity.new( id: 5 )
      id     = service.ids( entity ).first

      expect( service.record_ids( id ).first ).to eq( 5 )
    end
  end

  describe "#lookup" do
    let( :examples_service ) { double( EntityLookupServiceSpecs::ExamplesService ) }

    before( :each ) do
      allow( service.scorpion ).to receive( :fetch )
        .with( EntityLookupServiceSpecs::ExamplesService )
        .and_return( examples_service )
    end

    it "finds an entity" do
      expect( examples_service ).to receive( :lookup ).with( "4" ).and_return [ "Found" ]
      id = service.ids( "EntityLookupServiceSpecs::Example[4]" ).first

      expect( service.lookup( id ).to_a ).to eq [ "Found" ]
    end
  end
end
