require "spec_helper"

describe Shamu::JsonApi::BaseBuilder do
  let( :context ) { Shamu::JsonApi::Context.new }
  let( :builder ) { Shamu::JsonApi::BaseBuilder.new( context ) }

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

end