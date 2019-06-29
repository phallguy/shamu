require "spec_helper"

describe Shamu::JsonApi::RelationshipBuilder do
  let( :context ) { Shamu::JsonApi::Context.new }
  let( :builder ) { Shamu::JsonApi::ResourceBuilder.new( context ) }


  before( :each ) do
    builder.identifier "example", 1
  end

  describe "#identifier" do
    it "writes type and id" do
      builder.identifier "spec", 5

      expect( builder.compile ).to include type: "spec", id: "5"
    end
  end

  describe "#attribute" do
    it "adds to the attributes node" do
      builder.attribute name: "Jim"

      expect( builder.compile ).to include attributes: { name: "Jim" }
    end

    it "excludes filtered attributes" do
      allow( context ).to receive( :include_field? ).and_return false

      builder.attribute name: "Nope"
      expect( builder.compile ).not_to include attributes: { name: "Nope" }
    end
  end

  describe "#relationship" do
    it "adds a relationship" do
      builder.relationship :parent do |rel|
        rel.identifier :example, 5
      end

      expect( builder.compile ).to include relationships: { parent: kind_of( Hash ) }
    end

    it "excludes filtered relationships" do
      allow( context ).to receive( :include_field? ).and_return false

      builder.relationship :parent do |rel|
        rel.identifier :example, 5
      end

      expect( builder.compile ).not_to include relationships: { parent: kind_of( Hash ) }
    end
  end

  describe "#compile" do
    it "fails if identifier has not been specified" do
      expect do
        Shamu::JsonApi::ResourceBuilder.new( context ).compile
      end.to raise_error Shamu::JsonApi::IncompleteResourceError
    end
  end

end