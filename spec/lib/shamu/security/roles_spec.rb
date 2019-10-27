require "spec_helper"

describe Shamu::Security::Roles do
  module AdminRoles
    include Shamu::Security::Roles

    role :admin
    role :member
    role :reviewer, bit: 5
  end


  describe "#role" do
    it "adds a role" do
      klass = Class.new do
        include AdminRoles
      end

      expect( klass.roles ).to have_key :admin
      expect( klass.roles[:admin] ).to be_a Hash
      expect( klass.roles[:admin][:bit] ).to eq 0
      expect( klass.roles[:member][:bit] ).to eq 1
      expect( klass.roles[:reviewer][:bit] ).to eq 5
    end
  end

  describe "#expand_roles" do
    let( :roles ) do
      Module.new do
        include Shamu::Security::Roles

        role :admin, inherits: :manager
        role :manager, inherits: :user
        role :user
      end
    end

    let( :klass ) do
      Class.new.tap do |klass|
        klass.include roles
      end
    end

    it "returns all roles for :all" do
      expect( klass.expand_roles( :all ) ).to eq [ :admin, :manager, :user ]
    end

    it "includes base roles" do
      expect( klass.expand_roles( :user ) ).to include :user
    end

    it "excludes unknown roles" do
      expect( klass.expand_roles( :magician ) ).to be_empty
    end

    it "includes inherited roles" do
      expect( klass.expand_roles( :manager ) ).to include :user
    end

    it "includes inherited inherited roles" do
      expect( klass.expand_roles( :admin ) ).to include :manager
      expect( klass.expand_roles( :admin ) ).to include :user
    end
  end
end
