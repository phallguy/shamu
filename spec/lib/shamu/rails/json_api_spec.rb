require "rails_helper"

module JsonApiControllerSpec

  class Resource < Shamu::Entities::Entity
    attribute :id
    attribute :name
  end

  class ResourcesController < ActionController::Base
    include Shamu::Rails::JsonApi
  end

  module Resources
    class ResourcePresenter
      def present( resource, builder )
        builder.identifier :resource, resource.id
        builder.attribute name: resource.name
      end
    end
  end

end

describe JsonApiControllerSpec::ResourcesController, type: :controller do
  controller JsonApiControllerSpec::ResourcesController do
    def show
      resource = resources.first
      json_api resource: resource
    end

    def index
      json_api collection: resources
    end

    def nope
      json_api error: StandardError.new( "Nope" )
    end

    def resources
    end
  end

  let( :resource )  { JsonApiControllerSpec::Resource.new( id: 562, name: "Example" ) }
  let( :resources ) { [ resource ] }

  before( :each ) do
    allow( controller ).to receive( :_routes ).and_return @routes
    allow( controller ).to receive( :resources ).and_return resources
  end

  describe "#json_resource" do
    subject do
      get :show, id: 1, format: :json
      JSON.parse( response.body )
    end

    it { is_expected.to include "data" => kind_of( Hash ) }
    it { is_expected.to include "data" => hash_including( "attributes" => kind_of( Hash ) ) }

    it "reflects fields param to meta" do
      get :show, id: 1, fields: { people: "id,name" }
      json = JSON.parse( response.body )
      expect( json ).to include "meta" => hash_including( "fields" )
    end

    it "fails when 'include' paramter is given" do
      get :show, id: 1, include: :contact

      expect( response.code ).to eq "400"
      expect( response.body ).to include "include"
    end
  end

  describe "#json_collection" do
    before( :each ) do
      allow( controller.resources ).to receive( :current_page ).and_return 1
    end

    subject do
      get :index, format: :json
      JSON.parse( response.body )
    end

    it { is_expected.to include "data" => kind_of( Array ) }
    it { is_expected.to include "links" => hash_including( "next" ) }
  end

  it "writes an error" do
    routes.draw do
      get "nope" => "json_api_controller_spec/resources#nope"
    end

    get :nope
    json = JSON.parse( response.body )

    expect( json ).to include "errors"
  end

  describe "#json_context" do
    it "resolves namespaces from the controller" do
      expect( controller.send( :json_context_namespaces ) ).to eq [
        "JsonApiControllerSpec::Resources",
        "JsonApiControllerSpec"
      ]
    end
  end

end