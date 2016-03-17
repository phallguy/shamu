require "spec_helper"
require "shamu/rack"

describe Shamu::Rack::QueryParams do
  let( :headers )      { {} }
  let( :env )          { { "rack.input" => StringIO.new } }
  let( :query_params ) { Shamu::Rack::QueryParams.new( env ) }

  it "gets a cookie" do
    env[ "QUERY_STRING" ] = "toggles=yep"
    expect( query_params.get( "toggles" ) ).to eq "yep"
  end

  it "handles array parameters" do
    env[ "QUERY_STRING" ] = "level[]=one&level[]=two"
    expect( query_params.get( "level" ) ).to eq [ "one", "two" ]
  end

  it "handles hash parameters" do
    env[ "QUERY_STRING" ] = "option[save]=yes&option[method]=tail"
    expect( query_params.get( "option" ) ).to eq "save" => "yes", "method" => "tail"
  end
end