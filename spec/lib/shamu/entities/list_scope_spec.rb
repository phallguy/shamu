require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope do

  let( :klass ) do
    Class.new( Shamu::Entities::ListScope ) do
      def self.validates( * ); end

      attribute :name, presence: true
    end
  end

  describe ".coerce" do
    it "coerces an instance of the scope to self" do
      scope = klass.new
      expect( klass.coerce( scope ) ).to be scope
    end

    it "coerces a hash" do
      expect( klass.coerce( {} ) ).to be_a klass
    end

    it "coerces a nil" do
      expect( klass.coerce( nil ) ).to be_a klass
    end

    it "raises ArgumentError on other values" do
      expect do
        klass.coerce( "" )
      end.to raise_error ArgumentError
    end
  end

  describe ".coerce!" do
    it "raises ArgumentError if the scope has invalid params" do
      scope = klass.new( name: nil )
      expect( scope ).to receive( :valid? ).and_return false

      expect do
        klass.coerce!( scope )
      end.to raise_error ArgumentError
    end

    it "returns the scope if the params are valid" do
      scope = klass.new( name: nil )
      expect( scope ).to receive( :valid? ).and_return true

      expect do
        klass.coerce!( scope )
      end.not_to raise_error
    end
  end

  describe "#except" do
    it "excludes the requested params" do
      instance = klass.new( name: "Orca" )
      expect( instance.except( :name ).name ).to be_nil
    end

    it "returns an instance of the same class" do
      instance = klass.new( name: "Killer" )
      expect( instance.except ).to be_a klass
    end
  end

  describe "#params" do
    it "calls params on nested values" do
      name     = "Nested"
      instance = klass.new( name: name )
      expect( name ).to receive( :params ).and_return "parameterized"
      expect( instance.params[:name] ).to eq "parameterized"
    end
  end
end