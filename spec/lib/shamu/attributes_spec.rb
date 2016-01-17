require 'spec_helper'
require 'shamu/attributes'

describe Shamu::Attributes do
  let( :klass ) do
    Class.new do
      include Shamu::Attributes

      attribute :name
      attribute :info, on: :contact
      attribute :contact
      attribute :company, default: "ACME"
    end
  end

  describe "delegate" do

    it "delegates to another method" do
      contact = double
      expect( contact ).to receive( :info )

      instance = klass.new( contact: contact )
      instance.info
    end

    it "returns nil if delegate is nil" do
      expect( klass.new( contact: nil ).info ).to be_nil
    end

    it "fetches value only once" do
      contact = double
      expect( contact ).to receive( :info ){ Time.now.to_f }

      instance = klass.new( contact: contact )
      time = instance.info
      sleep 0.1
      expect( instance.info ).to eq time
    end

  end

  context "with block" do
    let( :klass ) do
      Class.new do
        include Shamu::Attributes

        attribute :time do
          Time.now.to_f
        end
      end
    end

    it "uses a block if provided" do
      expect( klass.new.time ).to be_a Float
    end

    it "computes value once" do
      instance = klass.new
      time = instance.time
      sleep 0.1
      expect( instance.time ).to eq time
    end
  end

  describe "defaults" do
    it "uses default if not set" do
      expect( klass.new({}).company ).to eq "ACME"
    end

    it "are overriden with a nil value" do
      expect( klass.new( company: nil ).company ).to be_nil
    end

    it "doesn't use any default if not defined" do
      expect( klass.new( {} ).name ).to be_nil
    end
  end

  it "uses instance variables" do
    instance = klass.new( name: "Example" )

    expect( instance.instance_variable_get :@name ).to eq "Example"
  end

  describe "inheritance" do
    let(:parent) do
      Class.new do
        include Shamu::Attributes

        attribute :name
      end
    end

    let( :child ) do
      Class.new( parent ) do
        attribute :email
      end
    end

    it "inherits parent attributes" do
      expect( child.attributes ).to have_key :name
      expect( child.attributes ).to have_key :email
    end

    it "does not modify parent attributes" do
      expect( parent.attributes ).not_to have_key :email
    end
  end
end
