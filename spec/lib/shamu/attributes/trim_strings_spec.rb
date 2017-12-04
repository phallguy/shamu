require "spec_helper"

describe Shamu::Attributes::TrimStrings do
  let( :base_klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::TrimStrings
    end
  end

  it "removes leading spaces" do
    klass = Class.new( base_klass ) do
      attribute :value, trim: :left
    end

    entity = klass.new value: "  A  "
    expect( entity.value ).to eq "A  "
  end

  it "removes trailing spaces" do
    klass = Class.new( base_klass ) do
      attribute :value, trim: :right
    end

    entity = klass.new value: "  A  "
    expect( entity.value ).to eq "  A"
  end

  it "removes leading and trailing spaces" do
    klass = Class.new( base_klass ) do
      attribute :value, trim: true
    end

    entity = klass.new value: "  A  "
    expect( entity.value ).to eq "A"
  end

  it "treats empty strings as nil" do
    klass = Class.new( base_klass ) do
      attribute :value, trim: true
    end

    entity = klass.new value: ""
    expect( entity.value ).to eq nil
  end

  it "trims arrays of strings" do
    klass = Class.new( base_klass ) do
      include Shamu::Attributes::Assignment
      attribute :value, trim: true, array: true
    end

    entity = klass.new value: [ "  AA  " ]
    expect( entity.value ).to eq [ "AA" ]
  end
end
