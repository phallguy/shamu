require "spec_helper"

describe Shamu::Security::Roles do

  describe "#role" do
    it "adds a role" do
      klass = Class.new do
        include Shamu::Security::Roles

        role :admin
      end

      expect( klass.roles ).to have_key :admin
      expect( klass.roles[:admin] ).to be_a Hash
    end
  end

  describe "#expand_roles" do
    let( :klass ) do
      Class.new do
        include Shamu::Security::Roles

        role :admin, inherits: :manager
        role :manager, inherits: :user
        role :user
      end
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