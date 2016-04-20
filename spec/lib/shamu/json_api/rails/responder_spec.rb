require "rails_helper"

module JsonApiResponderSpec

  class Resource < Shamu::Entities::Entity
    attribute :id
    attribute :name
  end

  class Responder < ActionController::Responder
    include Shamu::JsonApi::Rails::Responder
  end

  class ResourcesController < ActionController::Base
    include Shamu::JsonApi::Rails::Controller

    respond_to :json_api, :json
    self.responder = Responder

    def json_api_responder_spec_resource_url( * )
      "/go/here"
    end
  end

  module Resources
    class ResourcePresenter < Shamu::JsonApi::Presenter
      def present
        builder.identifier :resource, resource.id
        builder.attribute name: resource.name
      end
    end
  end

end

describe JsonApiResponderSpec::ResourcesController, type: :controller do
  controller JsonApiResponderSpec::ResourcesController do
    def show
      resource = resources.first
      respond_with resource
    end

    def create
      resource = resources.first
      respond_with resource
    end

    def update
      resource = resources.first
      respond_with resource
    end

    def index
      respond_with resources
    end

    def resources
    end
  end

  let( :resource )  { JsonApiResponderSpec::Resource.new( id: 562, name: "Example" ) }
  let( :resources ) { [ resource ] }
  let( :body )      { JSON.load( response.body, nil, symbolize_names: true ) }

  before( :each ) do
    allow( controller ).to receive( :_routes ).and_return @routes
    allow( controller ).to receive( :resources ).and_return resources
  end

  describe "#show" do
    it "has JSON content_type" do
      get :show, id: 1
      expect( response.content_type ).to eq Shamu::JsonApi::MIME_TYPE
    end

    it "renders JSON API response" do
      get :show, id: 1
      expect( body ).to include data: hash_including( id: resource.id.to_s )
    end

    it "renders errors on validation failure" do
      errors = ActiveModel::Errors.new( resource )
      errors.add :name, "can't be blank"
      allow( resource ).to receive( :errors ).and_return errors
      allow( resource ).to receive( :valid? ).and_return false

      get :show, id: 1
      expect( body ).to include :errors
    end
  end

  describe "#create" do
    it "has JSON content_type" do
      post :create
      expect( response.content_type ).to eq Shamu::JsonApi::MIME_TYPE
    end

    it "includes location header" do
      post :create
      expect( response.location ).to be_present
    end

    it "returns 201 status code" do
      post :create
      expect( response.status ).to eq 201
    end

    it "includes the json entity" do
      post :create
      expect( body ).to include data: hash_including( id: resource.id.to_s )
    end
  end

  describe "#update" do
    it "has JSON content_type" do
      put :update, id: 1
      expect( response.content_type ).to eq Shamu::JsonApi::MIME_TYPE
    end

    it "includes location header" do
      post :update, id: 1
      expect( response.location ).to be_present
    end

    it "returns 200 status code" do
      put :update, id: 1
      expect( response.status ).to eq 200
    end

    it "includes the json entity" do
      put :update, id: 1
      expect( body ).to include data: hash_including( id: resource.id.to_s )
    end
  end

  describe "#index" do
    it "has JSON content_type" do
      get :index
      expect( response.content_type ).to eq Shamu::JsonApi::MIME_TYPE
    end

    it "returns 200 status code" do
      get :index
      expect( response.status ).to eq 200
    end

    it "includes the json entity" do
      get :index
      expect( body ).to include data: include( hash_including( id: resource.id.to_s ) )
    end
  end

end