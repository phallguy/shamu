require "spec_helper"

describe Shamu::Attributes::CamelCase do
  let( :klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::CamelCase

      attribute :name
      attribute :camel_case
    end
  end

  it "responds to camelcased version" do
    expect( klass.new( camel_case: "Word" ).camelCase ).to eq "Word"
  end

  it "assigns camelized version from input args" do
    expect( klass.new( camelCase: "Word" ).camel_case ).to eq "Word"
  end

  it "allows short non-camelized words" do
    expect( klass.new( name: "Pete" ).name ).to eq "Pete"
  end

  it "assigns the original attribute" do
    instance = klass.new
    instance.camelCase = "Worked"

    expect( instance.camel_case ).to eq "Worked"
  end
end
