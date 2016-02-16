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

  describe ".for" do
    let( :namespace ) do
      Object.send( :remove_const, :EntityModule ) if defined? EntityModule
      EntityModule = Module.new
    end

    describe "with 'Entity' class" do
      let( :entity_class ) do
        namespace.const_set :ResourceEntity, Class.new( Shamu::Entities::Entity )
      end

      it "tries Namespace::EntityNameListScope" do
        klass = Class.new( Shamu::Entities::ListScope )
        namespace.const_set :ResourceListScope, klass
        expect( Shamu::Entities::ListScope.for( entity_class ) ).to be klass
      end

      it "tries Namespace::ListScope" do
        klass = Class.new( Shamu::Entities::ListScope )
        namespace.const_set :ListScope, klass
        expect( Shamu::Entities::ListScope.for( entity_class ) ).to be klass
      end

      it "falls back to ListScope" do
        expect( Shamu::Entities::ListScope.for( Shamu::Entities::Entity ) ).to be Shamu::Entities::ListScope
      end
    end

    describe "with unadorned entity class" do
      let( :entity_class ) do
        namespace.const_set :Resource, Class.new( Shamu::Entities::Entity )
      end

      it "tries Namespace::EntityNameListScope" do
        klass = Class.new( Shamu::Entities::ListScope )
        namespace.const_set :ResourceListScope, klass
        expect( Shamu::Entities::ListScope.for( entity_class ) ).to be klass
      end

      it "tries Namespace::ListScope" do
        klass = Class.new( Shamu::Entities::ListScope )
        namespace.const_set :ListScope, klass
        expect( Shamu::Entities::ListScope.for( entity_class ) ).to be klass
      end

      it "falls back to ListScope" do
        expect( Shamu::Entities::ListScope.for( Shamu::Entities::Entity ) ).to be Shamu::Entities::ListScope
      end
    end
  end

end