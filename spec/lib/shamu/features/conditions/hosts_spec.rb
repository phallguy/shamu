require "spec_helper"


describe Shamu::Features::Conditions::Hosts do
  let( :context ) { double( Shamu::Features::Context ) }
  let( :toggle )  { double( Shamu::Features::Toggle ) }

  it "matches using regex" do
    condition = scorpion.new Shamu::Features::Conditions::Hosts, [ 'web\d+' ], toggle

    expect( context ).to receive( :host ).and_return "web3"
    expect( condition.match?( context ) ).to be_truthy
  end

  it "doesn't match using regex" do
    condition = scorpion.new Shamu::Features::Conditions::Hosts, [ 'web\d+-staging' ], toggle

    expect( context ).to receive( :host ).and_return "web3"
    expect( condition.match?( context ) ).to be_falsy
  end
end