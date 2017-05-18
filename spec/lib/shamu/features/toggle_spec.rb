require "spec_helper"

describe Shamu::Features::Toggle do
  let( :path )    { File.expand_path( "../features.yml", __FILE__ ) }
  let( :toggles ) { Shamu::Features::Toggle.load( path ) }

  it "collapses path to name" do
    expect( toggles ).to have_key "shopping/buy_now"
  end

  it "imports relative files" do
    expect( toggles ).to have_key "shopping/offers/at_checkout"
  end

  context "with toggle" do
    let( :toggle ) { toggles[ "shopping/buy_now" ] }

    it "creates the toggle" do
      expect( toggle ).to be_a Shamu::Features::Toggle
    end

    it "parses selectors LIFO" do
      expect( toggle.selectors.count ).to eq 2
    end

    it "parses selector conditions" do
      expect( toggle.selectors.last.conditions.count ).to eq 7
    end
  end

  it "requires a retire_at date" do
     expect do
      Shamu::Features::Toggle.new( {} )
     end.to raise_error ArgumentError, /retire_at/
  end

  it "requires a type" do
     expect do
      Shamu::Features::Toggle.new( "retire_at" => Time.now )
     end.to raise_error ArgumentError, /Type/
  end
end
