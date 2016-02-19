require "spec_helper"

describe Shamu::Events::EventsService do
  let( :klass ) do
    Class.new( Shamu::Events::EventsService ) do
      public :serialize, :deserialize
    end
  end
  let( :service ) { scorpion.new klass }
  let( :message ) { Shamu::Events::Message.new }

  it "uses in-memory for default implementation" do
    expect( scorpion.fetch( Shamu::Events::EventsService ) ).to be_a Shamu::Events::InMemory::Service
  end

  it "gets the same service for each default scorpion resolution" do
    service = scorpion.fetch( Shamu::Events::EventsService )
    expect( scorpion.fetch( Shamu::Events::EventsService ) ).to be service
  end

  describe "#serialize" do
    it "generates a string" do
      expect( service.serialize( message ) ).to be_a String
    end
  end

  describe "#deserialize" do
    it "creates a Message from a string" do
      data         = service.serialize( message )
      deserialized = service.deserialize( data )

      expect( deserialized ).to be_a message.class
      expect( deserialized.id ).to eq message.id
    end
  end

  describe ".bridge" do
    let( :message ) { Shamu::Events::Message.new }

    let( :source_service ) { scorpion.fetch Shamu::Events::InMemory::Service }
    let( :target_service ) { double Shamu::Events::EventsService }

    before( :each ) do
      Shamu::Events::EventsService.bridge \
        source_service,
        target_service,
        "spec"
    end

    it "forwards messages" do
      expect( target_service ).to receive( :publish )

      source_service.publish "spec", message
      source_service.dispatch
    end
  end
end