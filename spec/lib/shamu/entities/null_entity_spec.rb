require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::NullEntity do
  let( :klass ) do
    Class.new( Shamu::Entities::Entity ) do
      def self.name
        "KillerWhale"
      end

      model :record

      attribute :name, on: :record
      attribute :email, on: :record
      attribute :id, on: :record
      attribute :group do
        email.present? ? "Emailers" : "Quieters"
      end
    end
  end

  let( :null_klass ) do
    Class.new( klass ) do
      include Shamu::Entities::NullEntity

      attribute :group, default: "Uncategorized"
    end
  end

  let( :record ) do
    OpenStruct.new \
      name: "Killer",
      email: "star@seaworld.com",
      id: 5
  end

  let( :entity ) do
    klass.new( record: record )
  end

  let( :null ) do
    null_klass.new
  end

  describe "#empty?" do
    it "is false for real entities" do
      expect( entity ).not_to be_empty
    end

    it "is true for null entitites" do
      expect( null ).to be_empty
    end
  end

  describe "attributes" do
    [ :title, :name, :label ].each do |attr|
      it "automatically formats '#{ attr }' value with 'Unknown Entity'" do
        auto_klass = Class.new( klass ) do
          attribute attr
        end

        auto_null_klass = Class.new( auto_klass ) do
          include Shamu::Entities::NullEntity
        end

        expect( auto_null_klass.new.send( attr ) ).to eq "Unknown Killer Whale"
      end
    end

    it "does not automatically format other attributes" do
      expect( null.email ).to be_nil
    end

    it "allow auto formatted to be overridden" do
      auto_null_klass = Class.new( klass ) do
        include Shamu::Entities::NullEntity

        attribute :name, default: "Missing"
      end

      expect( auto_null_klass.new.name ).to eq "Missing"
    end
  end

  describe ".for" do
    it "creates a null class" do
      expect( Shamu::Entities::NullEntity.for( klass ) ).to be < Shamu::Entities::NullEntity
    end

    it "inherits from the entity class" do
      expect( Shamu::Entities::NullEntity.for( klass ) ).to be < klass
    end

    it "uses same model name" do
      expect( Shamu::Entities::NullEntity.for( klass ).model_name ).to be klass.model_name
    end

  end
end
