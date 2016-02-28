require "spec_helper"

module ProcSpec
  class CustomProc
    def match?( context )
    end
  end
end

describe Shamu::Features::Conditions::Proc do
  let( :context ) { double( Shamu::Features::Context ) }
  let( :toggle )  { double( Shamu::Features::Toggle ) }

  it "invokes the specified match method" do
    expect( context ).to receive( :scorpion ).and_return scorpion

    condition = scorpion.new Shamu::Features::Conditions::Proc, "ProcSpec::CustomProc#match?", toggle

    instance = condition.send( :instance, context )
    expect( condition ).to receive( :instance ).and_return instance

    expect( instance ).to be_a ProcSpec::CustomProc
    expect( instance ).to receive( :match? ).with( context, toggle )

    condition.match?( context )
  end

end