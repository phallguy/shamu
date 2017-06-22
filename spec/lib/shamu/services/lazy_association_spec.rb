require "spec_helper"

describe Shamu::Services::LazyAssociation do
  let( :lazy_class ) { Shamu::Services::LazyAssociation.class_for( Shamu::Entities::Entity ) }

  it "calls block to look up association" do
    assoc = double
    expect( assoc ).to receive( :label )
    lazy = lazy_class.new( 1 ) { assoc }
    lazy.label
  end

  it "delegates ==" do
    assoc = double
    lazy = lazy_class.new( 1 ) { assoc }
    expect( lazy ).to eq assoc
  end

  it "does not delegate id" do
    assoc = double
    expect( assoc ).not_to receive( :id )
    lazy = lazy_class.new( 1 ) { assoc }
    lazy.id
  end

  it "has the same class as original object" do
    assoc = double Shamu::Entities::Entity
    expect( assoc ).to receive( :to_entity ).and_return assoc
    lazy = lazy_class.new( 1 ) { assoc }

    expect( lazy.to_entity ).to be_kind_of assoc.class
  end

  it "instance of" do
    lazy = lazy_class.new( 1 ) { Shamu::Entities::Entity.new }

    expect( lazy ).to be_a Shamu::Entities::Entity
  end

  it "satisfies case compare" do
    lazy = lazy_class.new( 1 ) { Shamu::Entities::Entity.new }
    expect( Shamu::Entities::Entity === lazy ).to be_truthy
  end
end
