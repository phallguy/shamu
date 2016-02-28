require "spec_helper"
require "shamu/active_record"

describe Shamu::Entities::ActiveRecordSoftDestroy do
  use_active_record

  let!( :zombie ) { ActiveRecordSpec::Favorite.create( name: "Zombie" ) }
  let!( :live )   { ActiveRecordSpec::Favorite.create( name: "Live" ) }

  describe "#destroy" do
    it "marks the record as destroyed" do
      zombie.destroy
      expect( ActiveRecordSpec::Favorite.unscoped.find( zombie.id ) ).to be_soft_destroyed
    end

    it "does not remove the record" do
      expect do
        zombie.destroy
      end.not_to change { ActiveRecordSpec::Favorite.unscoped.count }
    end

    it "really destroys if already marked destroyed" do
      zombie.destroy

      expect do
        ActiveRecordSpec::Favorite.unscoped.find( zombie.id ).destroy
      end.to change { ActiveRecordSpec::Favorite.unscoped.count }
    end
  end

  describe "#obliterate" do
    it "removes the record" do
      expect do
        zombie.obliterate
      end.to change { ActiveRecordSpec::Favorite.unscoped.count }
    end
  end

  context "with destroyed" do
    before( :each ) do
      zombie.destroy
    end

    describe "default_scope" do
      it "excludes destroyed records" do
        expect( ActiveRecordSpec::Favorite.all ).not_to include zombie
      end

      it "includes live records" do
        expect( ActiveRecordSpec::Favorite.all ).to include live
      end
    end

    describe ".including_destroyed" do
      it "includes destroyed records" do
        expect( ActiveRecordSpec::Favorite.including_destroyed ).to include zombie
      end

      it "includes live records" do
        expect( ActiveRecordSpec::Favorite.including_destroyed ).to include live
      end
    end

    describe ".destroyed" do
      it "includes destroyed records" do
        expect( ActiveRecordSpec::Favorite.destroyed ).to include zombie
      end

      it "does not include live records" do
        expect( ActiveRecordSpec::Favorite.destroyed ).not_to include live
      end
    end

    context "#undestroy" do
      it "restores the record" do
        zombie.undestroy

        expect( ActiveRecordSpec::Favorite.unscoped.find( zombie.id ) ).not_to be_soft_destroyed
      end
    end
  end
end