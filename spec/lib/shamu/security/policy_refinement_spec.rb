require "spec_helper"
require "shamu/active_record"

describe Shamu::Security::PolicyRefinement do
  use_active_record

  describe "#match?" do
    let( :relation ) { ActiveRecordSpec::Favorite.all }
    let( :refinement ) do
      Shamu::Security::PolicyRefinement.new( [ :read ], ActiveRecordSpec::Favorite, nil )
    end

    it "is true for matching action" do
      expect( refinement ).to be_match :read, relation, nil
    end

    it "is false for mismatched action" do
      expect( refinement ).not_to be_match :update, relation, nil
    end

    it "is true for matching relation" do
      expect( refinement ).to be_match :read, relation, nil
    end

    it "is false for mismatched relation" do
      klass = Class.new( ActiveRecord::Base )
      expect( refinement ).not_to be_match :read, klass.all, nil
    end
  end

  describe "#apply" do
    it "returns block result" do
      refinement = Shamu::Security::PolicyRefinement.new(
        [ :read ],
        ActiveRecordSpec::Favorite,
        ->( _, _ ) { :refined }
      )
      expect( refinement.apply( :read, ActiveRecordSpec::Favorite.all ) ).to eq :refined
    end

    it "returns original if no block" do
      refinement = Shamu::Security::PolicyRefinement.new(
        [ :read ],
        ActiveRecordSpec::Favorite,
        nil
      )
      relation = ActiveRecordSpec::Favorite.all
      expect( refinement.apply( relation, nil ) ).to be relation
    end

    it "returns original if block returns falsy value" do
      refinement = Shamu::Security::PolicyRefinement.new(
        [ :read ],
        ActiveRecordSpec::Favorite,
        ->( _, _ ) {}
      )
      relation = ActiveRecordSpec::Favorite.all
      expect( refinement.apply( relation, nil ) ).to be relation
    end
  end
end