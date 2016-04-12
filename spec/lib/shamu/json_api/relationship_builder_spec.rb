require "spec_helper"

describe Shamu::JsonApi::RelationshipBuilder do
  let( :context ) { Shamu::JsonApi::Context.new }
  let( :builder ) { Shamu::JsonApi::RelationshipBuilder.new( context ) }

  before( :each ) do
    builder.identifier "example", 1
  end

  describe "#compile" do
    it "fails if identifier has not been specified" do
      expect do
        Shamu::JsonApi::RelationshipBuilder.new( context ).compile
      end.to raise_error Shamu::JsonApi::IncompleteResourceError
    end
  end

  describe "#identifier" do
    it "writes type and id" do
      builder.identifier "spec", 5

      expect( builder.compile ).to include data: hash_including( type: "spec", id: "5" )
    end
  end

end