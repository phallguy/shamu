require "spec_helper"
require "shamu/active_record"

module ActiveRecordPolicySpec
  class Policy < Shamu::Security::ActiveRecordPolicy
    def permissions
      refine :none, ActiveRecord::Base
    end
  end
end

describe Shamu::Security::ActiveRecordPolicy do
  use_active_record

  let( :policy ) { ActiveRecordPolicySpec::Policy.new }

  describe "#refine_relation" do
    before( :each ) do
      ActiveRecordSpec::Favorite.create! name: "Example"
    end

    it "returns empty relation if there are no refinements" do
      relation = policy.refine_relation( :read, ActiveRecordSpec::Favorite.all )
      expect( relation ).to be_empty
    end

    it "applies matching refinements" do
      refinement = double( Shamu::Security::PolicyRefinement )
      allow( policy ).to receive( :refinements ).and_return [ refinement ]

      expect( refinement ).to receive( :match? ).and_return true
      expect( refinement ).to receive( :apply ).and_return ActiveRecordSpec::Favorite.all

      relation = policy.refine_relation( :read, ActiveRecordSpec::Favorite.all )
      expect( relation ).not_to be_empty
    end
  end

  describe "#refine" do
    it "adds a new refinement" do
      expect do
        policy.send( :refine, :read, ActiveRecordSpec::Favorite )
      end.to change { policy.send( :refinements ).length }
    end
  end
end
