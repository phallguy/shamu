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

  describe "#to_attributes" do
    let( :user )     { OpenStruct.new( name: "Heisenberg", email: "blue@rock.com" ) }
    let( :instance ) { klass.new( user: user ) }

    it "does not include model attributes" do
      expect( instance.to_attributes ).not_to have_key :user
    end
  end
end