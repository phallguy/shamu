require "spec_helper"
require "shamu/entities"


describe Shamu::Entities::Entity do
  let( :klass ) do
    Class.new( Shamu::Entities::Entity ) do
      model :user
      attribute :name, on: :user
      attribute :email, on: :user
    end
  end

  context "with instance" do
    let( :user )     { OpenStruct.new( name: "Heisenberg", email: "blue@rock.com" ) }
    let( :instance ) { klass.new( user: user ) }

    describe "#to_attributes" do

      it "does not include model attributes" do
        expect( instance.to_attributes ).not_to have_key :user
      end
    end

    describe "#redact" do
      it "clears the assigned attribute" do
        redacted = instance.redact( :name )
        expect( redacted.name ).to be_nil
      end

      it "it returns instance of the same type" do
        redacted = instance.redact( :name )
        expect( redacted ).to be_a klass
      end

      it "assigns redacted values" do
        redacted = instance.redact( name: "REDACTED" )
        expect( redacted.name ).to eq "REDACTED"
      end
    end
  end

  {
    "SetEntity" => "Set",
    "Set" => "Set",
    "Domain::SetEntity" => "Domain::Set",
    "Domain::SubDomain::SetEntity" => "Domain::SubDomain::Set",
    "Domain::SubDomain::SetsEntity" => "Domain::SubDomain::Set",
  }.each do |full_name, expected|

    it "maps #{ full_name } to #{ expected }" do
      klass = Class.new( Shamu::Entities::Entity )
      klass.define_singleton_method :name do
        full_name
      end

      expect( klass.model_name.name ).to eq expected
    end
  end

  describe ".null_entity" do
    it "defines a NullEntity class" do
      expect( klass.null_entity ).to be < Shamu::Entities::NullEntity
    end

    it "overrides attributes with default values" do
      klass.null_entity do
        attribute :name do
          "Unknown"
        end
      end

      expect( klass.null_entity.new.name ).to eq "Unknown"
    end
  end
end
