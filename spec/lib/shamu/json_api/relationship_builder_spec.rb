require "spec_helper"

describe Shamu::JsonApi::RelationshipBuilder do
  let(:context) { Shamu::JsonApi::Context.new }
  let(:builder) { Shamu::JsonApi::RelationshipBuilder.new(context) }

  describe "#compile" do
    before(:each) do
      builder.identifier("example", 1)
    end

    it "fails if identifier has not been specified" do
      expect do
        Shamu::JsonApi::RelationshipBuilder.new(context).compile
      end.to(raise_error(Shamu::JsonApi::IncompleteResourceError))
    end

    it "succeeds if a self link has been provided" do
      Shamu::JsonApi::RelationshipBuilder.new(context)
        .link(:self, "http://example.api")
        .compile
    end
  end

  describe "#identifier" do
    it "writes type and id" do
      builder.identifier("spec", 5)

      expect(builder.compile).to(include(data: hash_including(type: "spec", id: "5")))
    end
  end

  describe "#collection" do
    it "writes an array of type and ids" do
      builder.collection([{}]) do |_resource, linkage|
        linkage.identifier("spec", 7)
      end

      expect(builder.compile).to(include(data: include(hash_including(type: "spec", id: "7"))))
    end
  end

  describe "#missing_one" do
    it "sets the data node to null" do
      output =
        Shamu::JsonApi::RelationshipBuilder.new(context)
          .missing_one
          .compile

      expect(output).to(have_key(:data))
      expect(output[:data]).to(be_nil)
    end
  end

  describe "#missing_many" do
    it "sets the data node to an empty array" do
      output =
        Shamu::JsonApi::RelationshipBuilder.new(context)
          .missing_many
          .compile

      expect(output).to(have_key(:data))
      expect(output[:data]).to(eq([]))
    end
  end
end