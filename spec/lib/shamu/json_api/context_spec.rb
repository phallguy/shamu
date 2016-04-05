require "spec_helper"

module JsonApiContextSpec
  class SymbolPresenter < Shamu::JsonApi::Presenter
  end

  class Resource
    include Shamu::Attributes
  end
end

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

  describe "#find_presenter" do
    it "finds explicitly defined presenter" do
      klass = Class.new( Shamu::JsonApi::Presenter )

      context = Shamu::JsonApi::Context.new presenters: { String => klass }
      expect( context.find_presenter( "Ms. Piggy" ) ).to be_a klass
    end

    it "finds implicitly named presenter in namespaces" do
      context = Shamu::JsonApi::Context.new namespaces: [ "JsonApiContextSpec" ]
      expect( context.find_presenter( :symbols ) ).to be_a JsonApiContextSpec::SymbolPresenter
    end

    it "finds implicitly named model_name presenter in namespaces" do
      resource = double model_name: ActiveModel::Name.new( Class, nil, "JsonApiContextSpec::Symbol" )
      context = Shamu::JsonApi::Context.new namespaces: [ "JsonApiContextSpec" ]
      expect( context.find_presenter( resource ) ).to be_a JsonApiContextSpec::SymbolPresenter
    end

    it "raises if no presenter can be found" do
      expect do
        Shamu::JsonApi::Context.new.find_presenter double
      end.to raise_error Shamu::JsonApi::NoPresenter
    end
  end
end