require "spec_helper"
require_relative "entity_lookup_models"


describe Shamu::Entities::EntityLookupService do

  let( :service ) do
    scorpion.new( Shamu::Entities::EntityLookupService, { "Water" => EntityLookupServiceSpecs::CustomService }, {} )
  end

  describe "#service_class_for" do
    it "finds default service" do
      expect( service.service_class_for( "EntityLookupServiceSpecs::Example" ) ).to be \
        EntityLookupServiceSpecs::ExamplesService
    end

    it "uses custom service" do
      expect( service.service_class_for( "Water" ) ).to be EntityLookupServiceSpecs::CustomService
    end
  end

  describe "#ids" do
    it "maps entities to their entity path" do
      entity = EntityLookupServiceSpecs::ExampleEntity.new( id: 5 )
      expect( service.ids( entity ) ).to eq( [ "EntityLookupServiceSpecs::Example[5]" ] )
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
    let( :custom_service )   { double( EntityLookupServiceSpecs::CustomService ) }

    before( :each ) do
      allow( service.scorpion ).to receive( :fetch )
        .with( EntityLookupServiceSpecs::ExamplesService )
        .and_return( examples_service )

      allow( service.scorpion ).to receive( :fetch )
        .with( EntityLookupServiceSpecs::CustomService )
        .and_return( custom_service )
    end

    it "finds an entity" do
      expect( examples_service ).to receive( :lookup ).with( "4" ).and_return [ "Found" ]

      expect( service.lookup( "EntityLookupServiceSpecs::Example[4]" ).to_a ).to eq [ "Found" ]
    end

    it "batches common entity types" do
      expect( examples_service ).to receive( :lookup ).with( "4", "91" ).and_return( [ "One", "Two" ] )

      returned = service.lookup( "EntityLookupServiceSpecs::Example[4]", "EntityLookupServiceSpecs::Example[91]" )
      expect( returned.to_a ).to eq [ "One", "Two" ]
    end

    it "returns in same order" do
      expect( examples_service ).to receive( :lookup ).with( "4", "91" ).and_return( [ "One", "Two" ] )
      expect( custom_service ).to receive( :lookup ).with( "500" ).and_return( [ "Agua" ] )

      returned = service.lookup( "EntityLookupServiceSpecs::Example[4]",
                                 "Water[500]",
                                 "EntityLookupServiceSpecs::Example[91]" )

      expect( returned.to_a ).to eq [ "One", "Agua", "Two" ]
    end

  end
end
