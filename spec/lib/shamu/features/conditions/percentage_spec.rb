require "spec_helper"


describe Shamu::Features::Conditions::Percentage do
  let( :context ) { double( Shamu::Features::Context ) }
  let( :toggle )  { double( Shamu::Features::Toggle ) }

  before( :each ) do
    allow( toggle ).to receive( :name ).and_return "1z141z4" # 4294967296.to_s( 36 )
  end

  it "matches integer user id" do
    condition = scorpion.new Shamu::Features::Conditions::Percentage, 5, toggle

    expect( context ).to receive( :user_id ).at_least(:once).and_return 50
    expect( condition.match?( context ) ).to be_truthy
  end

  it "matches same user id when percentage grows" do
    condition = scorpion.new Shamu::Features::Conditions::Percentage, 15, toggle

    expect( context ).to receive( :user_id ).at_least(:once).and_return 50
    expect( condition.match?( context ) ).to be_truthy
  end

  it "excludes integer user id" do
    condition = scorpion.new Shamu::Features::Conditions::Percentage, 5, toggle

    expect( context ).to receive( :user_id ).at_least(:once).and_return 51
    expect( condition.match?( context ) ).to be_falsy
  end


  it "matches uuid user id" do
    condition = scorpion.new Shamu::Features::Conditions::Percentage, 7, toggle

    expect( context ).to receive( :user_id ).at_least(:once).and_return "45561ca3-5bf9-4f3a-9b4f-89a15ea0e387"
    expect( condition.match?( context ) ).to be_truthy
  end

  context "when no user_id" do
    before( :each ) do
      allow( context ).to receive( :user_id ).and_return nil
      allow( context ).to receive( :sticky! )
    end

    it "assigns randomly" do
      condition = scorpion.new Shamu::Features::Conditions::Percentage, 5, toggle

      expect( Random ).to receive( :rand ).and_return 0
      expect( condition.match?( context ) ).to be_truthy

      expect( Random ).to receive( :rand ).and_return 8
      expect( condition.match?( context ) ).to be_falsy
    end

    it "makes the assignment sticky" do
      condition = scorpion.new Shamu::Features::Conditions::Percentage, 5, toggle

      expect( Random ).to receive( :rand ).and_return 0
      expect( context ).to receive( :sticky! )
      condition.match?( context )
    end

    it "is always true at 100%" do
      condition = scorpion.new Shamu::Features::Conditions::Percentage, 100, toggle
      expect( condition.match?( context ) ).to be_truthy
    end
  end

end