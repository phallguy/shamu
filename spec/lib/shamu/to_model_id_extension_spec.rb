require "spec_helper"

describe Shamu::ToModelIdExtension do
  before( :each ) do
    Shamu::ToModelIdExtension.extend!
  end

  describe Shamu::ToModelIdExtension::Strings do

    {
      "7432" => 7432,
      "   123" => 123,
      "one" => nil,
      "99 bottles" => nil
    }.each do |candidate, expected|
      it "converts '#{ candidate }' to #{ expected }" do
        expect( candidate.to_model_id ).to eq expected
      end
    end
  end

  describe Shamu::ToModelIdExtension::Integers do
    it "returns self for an integer" do
      expect( 789.to_model_id ).to eq 789
    end

    it "returns nil for nil" do
      expect( nil.to_model_id ).to eq nil
    end
  end

  describe Shamu::ToModelIdExtension::Enumerables do
    it "maps array to ids" do
      expect( [ 567 ].to_model_id ).to eq [ 567 ]
    end
  end

  describe Shamu::ToModelIdExtension::Models do
    use_active_record

    it "ActiveRecord instances returns their id" do
      instance = ActiveRecordSpec::Favorite.new( id: 48 )
      expect( instance ).to receive( :id ).at_least( :once ).and_call_original
      expect( instance.to_model_id ).to eq instance.id
    end

    it "Entities instances returns their id" do
      klass = Class.new( Shamu::Entities::Entity ) do
        attribute :id
      end

      instance = klass.new id: 491
      expect( instance ).to receive( :id ).at_least( :once ).and_call_original
      expect( instance.to_model_id ).to eq instance.id
    end
  end

end
