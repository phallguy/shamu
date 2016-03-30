require "spec_helper"

describe Shamu::JsonApi::Context do
  it "parses comma deliminated fields" do
    context = Shamu::JsonApi::Context.new fields: { "user" => "name, email," }

    expect( context.send( :fields ) ).to eq user: [:name, :email]
  end

  it "accepts array of fields" do
    context = Shamu::JsonApi::Context.new fields: { "user" => [ "name", "email" ] }

    expect( context.send( :fields ) ).to eq user: [:name, :email]
  end

  describe "#include_field?" do
    let( :context ) { Shamu::JsonApi::Context.new( fields: { "user": "name,email" } ) }

    it "is true for unfiltered" do
      expect( context.include_field?( :order, :number ) ).to be_truthy
    end

    it "is true for filtered with field" do
      expect( context.include_field?( :user, :name ) ).to be_truthy
    end

    it "is false for filtered without field" do
      expect( context.include_field?( :user, :birthdate ) ).not_to be_truthy
    end
  end
end