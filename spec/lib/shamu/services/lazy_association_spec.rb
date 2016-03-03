require "spec_helper"

describe Shamu::Services::LazyAssociation do
  it "calls block to look up association" do
    assoc = double
    expect( assoc ).to receive( :label )
    lazy = Shamu::Services::LazyAssociation.new( 1 ) { assoc }
    lazy.label
  end

  it "delegates ==" do
    assoc = double
    lazy = Shamu::Services::LazyAssociation.new( 1 ) { assoc }
    expect( lazy ).to eq assoc
  end

  it "does not delegate id" do
    assoc = double
    expect( assoc ).not_to receive( :id )
    lazy = Shamu::Services::LazyAssociation.new( 1 ) { assoc }
    lazy.id
  end

  it "has the same class as original object" do
    assoc = double
    expect( assoc ).to receive( :to_entity ).and_return assoc
    lazy = Shamu::Services::LazyAssociation.new( 1 ) { assoc }

    expect( lazy.to_entity ).to be_kind_of assoc.class
  end
end