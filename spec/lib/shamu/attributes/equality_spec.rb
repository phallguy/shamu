require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::Equality do
  let(:klass) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::Equality

      attribute :name
      attribute :random, ignore_equality: true
      attribute :time
    end
  end

  let(:value)     { klass.new(name: "same") }
  let(:same)      { klass.new(name: "same") }
  let(:different) { klass.new(name: "different") }

  it "is eql? for the same attributes" do
    expect(value).to(eq(same))
  end

  it "isn't eql? for different attributes" do
    expect(value).not_to(eq(different))
  end

  it "isn't eql? for different types with the same attributes" do
    other_klass = Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Equality

      attribute :name
    end

    other = other_klass.new(name: value.name)

    expect(value).not_to(eq(other))
  end

  it "is eql? for derived types with same attributes" do
    derived_klass = Class.new(klass)
    derived = derived_klass.new(name: value.name)

    expect(value).to(eq(derived))
    expect(derived).to(eq(value))
  end

  it "is eql for time like values with very close times" do
    value.time = Time.at(1_514_709_141.299816)
    same.time = Time.at(1_514_709_141.299817)

    expect(value).to(eq(same))
  end

  it "has the same hash for the same attributes" do
    expect(value.hash).to(eq(same.hash))
  end

  it "has a different hash for different attributes" do
    expect(value.hash).not_to(eq(different.hash))
  end

  it "ignores excluded attributes" do
    v1 = klass.new(name: "same", random: 123)
    v2 = klass.new(name: "same", random: 456)

    expect(v1).to(eq(v2))
  end
end
