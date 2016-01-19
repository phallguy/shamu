require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::FluidAssignment do
  let( :klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::FluidAssignment

      attribute :value
    end
  end

  it "returns the current value with no arguments" do
    instance = klass.new( value: "one" )

    expect( instance.value ).to eq "one"
  end

  it "assigns the value when arguments present" do
    instance = klass.new
    instance.value( "two" )
  end

  it "return self on assignment" do
    instance = klass.new
    expect( instance.value( "two" ) ).to be instance
  end

end