require "spec_helper"

describe Shamu::Security::Principal do

  describe "#scoped?" do
    it "is true for any scope when not limited" do
      principal = Shamu::Security::Principal.new scopes: nil

      expect( principal ).to be_scoped :all
      expect( principal ).to be_scoped :bananas
    end

    it "is true for given scope" do
      principal = Shamu::Security::Principal.new scopes: [ :admin ]

      expect( principal ).to be_scoped :admin
    end

    it "is false for ungiven scope" do
      principal = Shamu::Security::Principal.new scopes: [ :admin ]

      expect( principal ).not_to be_scoped :bananas
    end
  end
end
