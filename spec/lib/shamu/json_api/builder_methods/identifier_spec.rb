require "spec_helper"

module BuilderMethodsIdentifierSpec
  class Builder
    include Shamu::JsonApi::BuilderMethods::Identifier

    attr_reader :output

    def initialize
      @output = {}
    end
  end
end

describe Shamu::JsonApi::BuilderMethods::Identifier do
  let( :builder ) { BuilderMethodsIdentifierSpec::Builder.new }

  it "it uses #json_type if available" do
    type = double( json_type: "magic" )

    builder.identifier( type )
    expect( builder.output[ :type ] ).to eq "magic"
  end

  it "it uses #model_name if available" do
    type = double( model_name: double( element: "record" ) )

    builder.identifier( type )
    expect( builder.output[ :type ] ).to eq "record"
  end

  it "it uses class name as last resort" do
    builder.identifier( BuilderMethodsIdentifierSpec::Builder )

    expect( builder.output[ :type ] ).to eq "builder"
  end

  it "gets ID from type ifid not provided" do
    resource = double( id: 56, json_type: "double" )

    builder.identifier resource
    expect( builder.output[ :id ] ).to eq "56"
    expect( builder.output[ :type ] ).to eq "double"
  end
end
