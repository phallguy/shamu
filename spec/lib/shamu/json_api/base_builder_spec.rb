require "spec_helper"

describe Shamu::JsonApi::BaseBuilder do
  let( :context ) { Shamu::JsonApi::Context.new }
  let( :builder ) { Shamu::JsonApi::BaseBuilder.new( context ) }

  before( :each ) do
    builder.identifier "example", 1
  end

  describe "#identifier" do
    it "writes type and id" do
      builder.identifier "spec", 5

      expect( builder.compile ).to include type: "spec", id: "5"
    end
  end

  describe "#link" do
    it "adds a link" do
      builder.link :self, "http://localhost"

      expect( builder.compile ).to include links: { self: "http://localhost" }
    end
  end

  describe "#meta" do
    it "adds the meta data" do
      builder.meta :updated, "today"

      expect( builder.compile ).to include meta: { updated: "today" }
    end
  end

  describe "#compile" do
    it "fails if identifier has not been specified" do
      expect do
        Shamu::JsonApi::BaseBuilder.new( context ).compile
      end.to raise_error Shamu::JsonApi::IncompleteResourceError
    end
  end
end