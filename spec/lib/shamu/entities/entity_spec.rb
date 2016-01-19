require 'spec_helper'
require 'shamu/entities'

describe Shamu::Entities::Entity do
  let( :klass ) do
    Class.new( Shamu::Entities::Entity ) do
      model :user
      attribute :name, on: :user
      attribute :email, on: :user
    end
  end

  describe "#to_attributes" do
    let( :user )     { OpenStruct.new( name: "Heisenberg", email: "blue@rock.com" ) }
    let( :instance ) { klass.new( user: user ) }

    subject { instance.to_attributes }

    it { is_expected.to have_key :name }
    it { is_expected.to have_key :email }
    it { is_expected.not_to have_key :user }

    it "includes only requested attributes array" do
      attrs = instance.to_attributes( only: :name )

      expect( attrs ).to have_key :name
      expect( attrs ).not_to have_key :email
    end

    it "includes only requested attributes regex" do
      attrs = instance.to_attributes( only: /email/ )

      expect( attrs ).not_to have_key :name
      expect( attrs ).to have_key :email
    end

    it "excludes requested attributes array" do
      attrs = instance.to_attributes( except: :name )

      expect( attrs ).not_to have_key :name
      expect( attrs ).to have_key :email

    end

    it "excludes requested attributes regex" do
      attrs = instance.to_attributes( except: /email/ )

      expect( attrs ).to have_key :name
      expect( attrs ).not_to have_key :email
    end

    it "invokes to_attributes of nested attributes" do
      user.name = double
      expect( user.name ).to receive( :to_attributes )

      instance.to_attributes
    end

    it "can be used to clone the entity" do
      instance = klass.new( name: "Peter", email: "parker@marvel.com" )
      clone    = klass.new( instance )

      expect( clone.name ).to eq "Peter"
    end
  end
end