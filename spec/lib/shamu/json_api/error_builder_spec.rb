require "spec_helper"

describe Shamu::JsonApi::ErrorBuilder do
  let(:builder) { Shamu::JsonApi::ErrorBuilder.new }

  describe "#exception" do
    before(:each) do
      builder.exception(NotImplementedError.new("Nope, we haven't done that yet"))
    end

    it "applies message to details" do
      expect(builder.compile).to(include(detail: "Nope, we haven't done that yet"))
    end

    it "applies class name as code" do
      expect(builder.compile).to(include(code: "not_implemented"))
    end

    it "applies class name as title" do
      expect(builder.compile).to(include(title: "Not Implemented"))
    end
  end
end