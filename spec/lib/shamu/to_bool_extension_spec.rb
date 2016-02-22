require "spec_helper"


describe Shamu::ToBoolExtension do
  before( :each ) do
    Shamu::ToBoolExtension.extend!
  end

  describe Shamu::ToBoolExtension::Strings do
    {
      "1"     => true,
      "0"     => false,
      "true"  => true,
      "false" => false,
      ""      => false,
      "True"  => true,
      "False" => false,
      "T"     => true,
      "F"     => false,
      "Yes"   => true,
      "No"    => false,
      "Y"     => true,
      "N"     => false,
    }.each do |candidate, expected|
      it "converts '#{ candidate }' to #{ expected }" do
        expect( candidate.to_bool ).to eq expected
      end
    end

    it "uses default for no-match" do
      expect( "Random".to_bool( :nope ) ).to eq :nope
    end
  end

  describe Shamu::ToBoolExtension::Integers do
    {
      1    => true,
      0    => false
    }.each do |candidate, expected|
      it "converts '#{ candidate }' to #{ expected }" do
        expect( candidate.to_bool ).to eq expected
      end
    end

    it "uses default for no-match" do
      expect( 100.to_bool( :nope ) ).to eq :nope
    end
  end

  describe Shamu::ToBoolExtension::Boolean do
    {
      true  => true,
      false => false,
    }.each do |candidate, expected|
      it "converts '#{ candidate }' to #{ expected }" do
        expect( candidate.to_bool ).to eq expected
      end
    end
  end

  describe Shamu::ToBoolExtension::Nil do
    it "uses default" do
      expect( nil.to_bool( :whatever ) ).to eq( :whatever )
    end
  end

end