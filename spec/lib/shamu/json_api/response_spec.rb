require "spec_helper"

describe Shamu::JsonApi::Response do
  let( :context )  { Shamu::JsonApi::Context.new }
  let( :response ) { Shamu::JsonApi::Response.new context }

  it "uses serializer if given" do
    serializer = double Shamu::JsonApi::Serializer
    expect( serializer ).to receive( :serialize ) do |builder|
      builder.identifier :response, 9
    end

    response.resource double, serializer
  end

  it "expects a block if no serializer" do
    expect do
      response.resource double
    end.to raise_error /block/
  end

  it "appends included resources" do

    response.resource double do |builder|
      builder.identifier :example, 4
      builder.relationship :parent do |rel|
        rel.identifier :suite, 10
        rel.include_resource double do |res|
          res.identifier :suite, 10
        end
      end
    end

    expect( response.compile ).to include included: [ hash_including( type: "suite" ) ]
  end

  it "includes errors" do
    response.error NotImplementedError.new

    expect( response.compile ).to include errors: [ hash_including( code: "not_implemented" ) ]
  end
end