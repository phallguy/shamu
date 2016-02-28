require "spec_helper"


describe Shamu::Features::Conditions::Env do
  let( :context ) { double( Shamu::Features::Context ) }
  let( :toggle )  { double( Shamu::Features::Toggle ) }

  it "matches on presence of truthy variable" do
    condition = scorpion.new Shamu::Features::Conditions::Env, "CANARY", toggle

    expect( context ).to receive( :env ).with( "CANARY" ).and_return "true"
    expect( condition.match?( context ) ).to be_truthy
  end

  it "matches on variable value" do
    condition = scorpion.new Shamu::Features::Conditions::Env, { "CANARY" => "example" }, toggle

    expect( context ).to receive( :env ).with( "CANARY" ).and_return "example"
    expect( condition.match?( context ) ).to be_truthy
  end

  it "doesn't match with invalid variable" do
    condition = scorpion.new Shamu::Features::Conditions::Env, "MISSING_ENV_VARIABLE_NAME", toggle

    expect( context ).to receive( :env ).with( "MISSING_ENV_VARIABLE_NAME" ).and_return nil
    expect( condition.match?( context ) ).to be_falsy
  end

end