require "rails_helper"

module JsonApiControllerSpec
  class Resource < Shamu::Entities::Entity
    attribute :id
    attribute :name
  end

  class ResourcesController < ActionController::Base
    include Shamu::JsonApi::Rails::Controller
  end

  module Resources
    class ResourcePresenter < Shamu::JsonApi::Presenter
      def present
        builder.identifier(:resource, resource.id)
        builder.attribute(name: resource.name)

        builder.link(:self, "somewhere")
      end
    end
  end
end

describe JsonApiControllerSpec::ResourcesController, type: :controller do
  controller JsonApiControllerSpec::ResourcesController do
    def show
      render_resource(resources.first)
    end

    def index
      render_collection(resources)
    end

    def create
      result = Shamu::Services::Result.new(resources.first)
      render_result(result)
    end

    def update
      result = Shamu::Services::Result.new(resources.first)
      render_result(result)
    end

    def destroy
      result = Shamu::Services::Result.new(resources.first)
      render_result(result)
    end

    def invalid
      result = Shamu::Services::Result.new
      result.errors.add(:base, "nope")

      render_result(result)
    end

    def no_entity
      result = Shamu::Services::Result.new
      render_result(result)
    end

    def nope
      render json: json_error(StandardError.new("Nope"))
    end

    def resources; end
  end

  let(:resource)  { JsonApiControllerSpec::Resource.new(id: 562, name: "Example") }
  let(:resources) { [resource] }

  before(:each) do
    allow(controller).to(receive(:_routes).and_return(@routes))
    allow(controller).to(receive(:resources).and_return(resources))
  end

  describe "#json_resource" do
    subject do
      get :show, params: { id: 1, format: :json }
      JSON.parse(response.body)
    end

    it { is_expected.to(include("data" => kind_of(Hash))) }
    it { is_expected.to(include("data" => hash_including("attributes" => kind_of(Hash)))) }

    it "reflects fields param to meta" do
      get :show, params: { id: 1, fields: { people: "id,name" } }
      json = JSON.parse(response.body)
      expect(json).to(include("meta" => hash_including("fields")))
    end

    it "fails when 'include' paramter is given" do
      get :show, params: { id: 1, include: :contact }

      expect(response.code).to(eq("400"))
      expect(response.body).to(include("include"))
    end
  end

  describe "#render_resource" do
    it "adds Location header" do
      get :show, params: { id: 1 }
      expect(response.headers).to(include("Location"))
    end
  end

  describe "#render_result" do
    it "returns status created on #create" do
      post :create, params: { name: "example" }
      expect(response.status).to(eq(201))
      expect(response.body).to(include("data"))
    end

    it "returns status ok on #update" do
      put :update, params: { id: 1 }

      expect(response.status).to(eq(200))
      expect(response.body).to(include("data"))
    end

    it "returns status no_content on delete" do
      delete :destroy, params: { id: 1 }

      expect(response.status).to(eq(204))
    end

    it "returns status bad_request on error" do
      routes.draw do
        post "invalid" => "json_api_controller_spec/resources#invalid"
      end

      post :invalid

      expect(response.status).to(be(422))
      expect(response.body).to(include("errors"))
    end

    it "returns status no_content on success without entity" do
      routes.draw do
        post "no_entity" => "json_api_controller_spec/resources#no_entity"
      end

      post :no_entity

      expect(response.status).to(eq(204))
      expect(response.body).to(be_blank)
    end
  end

  describe "#json_collection" do
    before(:each) do
      allow(controller.resources).to(receive(:current_page).and_return(1))
      allow(controller.resources).to(receive(:paged?).and_return(true))
    end

    subject do
      get :index
      JSON.parse(response.body)
    end

    it { is_expected.to(include("data" => kind_of(Array))) }
    it { is_expected.to(include("links" => include("next" => match(/page.*number/)))) }
  end

  describe "#json_pagination" do
    it "parses pagination parameters" do
      controller.params[:page] = { number: 3 }
      pagination = controller.send(:json_pagination)

      expect(pagination.number).to(eq(3))
    end

    it "parses nested pagination parameters" do
      controller.params[:users] = { page: { number: 5 } }
      pagination = controller.send(:json_pagination, :users)

      expect(pagination.number).to(eq(5))
    end
  end

  describe "#json_sort" do
    {
      "name" => { name: :asc },
      "-name" => { name: :desc },
      "name,email" => { name: :asc, email: :asc },
      "name,-email" => { name: :asc, email: :desc },
      "author.name,-email" => { "author.name": :asc, email: :desc },
    }
      .each do |raw, parsed|
      it "parses #{raw} to #{parsed}" do
        controller.params[:sort] = raw
        sort = controller.send(:json_sort)

        expect(sort).to(eq(parsed))
      end
    end

    it "handles nested sort params" do
      controller.params[:users] = { sort: "name" }
      sort = controller.send(:json_sort, :users)

      expect(sort).to(eq(name: :asc))
    end
  end

  describe "#json_filter" do
    it "symbolizes keys" do
      controller.params[:filter] = { "name" => "bat" }
      filter = controller.send(:json_filter)

      expect(filter).to(eq(name: "bat"))
    end

    it "handles nested filter params" do
      controller.params[:users] = { filter: { name: "bat" } }
      filter = controller.send(:json_filter, :users)

      expect(filter).to(eq(name: "bat"))
    end
  end

  it "writes an error" do
    routes.draw do
      get "nope" => "json_api_controller_spec/resources#nope"
    end

    get :nope
    json = JSON.parse(response.body)

    expect(json).to(include("errors"))
  end

  describe "#json_context" do
    it "resolves namespaces from the controller" do
      expect(controller.send(:json_context_namespaces)).to(eq([
        "JsonApiControllerSpec::Resources",
        "JsonApiControllerSpec",
      ]))
    end

    it "shares the controller scorpion" do
      expect(controller.send(:json_context).scorpion).to(eq(controller.scorpion))
    end
  end

  describe "#request_params" do
    let(:body) do
      {
        data: {
          attributes: {
            name: "Example",
          },
          relationships: {
            book: {
              data: { type: "book", id: "5", attributes: { title: "Bibliography" } },
            },
            stores: {
              data: [
                { type: "store", id: "56", attributes: { title: "First Street" } },
              ],
            },
          },
        },
      }
    end

    before(:each) do
      expect(request).to(receive(:body) { StringIO.new(body.to_json) })
    end

    it "maps data attributes" do
      expect(controller.send(:request_params, :example)).to(include(name: "Example"))
    end

    it "maps relationship ids to root attributes" do
      expect(controller.send(:request_params, :example)).to(include(book_id: "5"))
      expect(controller.send(:request_params, :example)).to(include(store_ids: ["56"]))
    end

    it "maps relationship data to root attributes" do
      expect(controller.send(:request_params, :example)).to(include(book: { id: "5", title: "Bibliography" }))
      expect(controller.send(:request_params, :example)).to(include(stores: [{ id: "56", title: "First Street" }]))
    end

    it "maps nil relationship data to root attributes" do
      body[:data][:relationships][:book][ :data ] = nil

      expect(controller.send(:request_params, :example)).to(include(book: nil))
    end

    it "maps data id if available" do
      body[:data][ :id ] = "73"

      expect(controller.send(:request_params, :example)).to(include(id: "73"))
    end

    it "maps id request params if available" do
      allow(controller.request).to(receive(:params).and_return({ id: "90" }.with_indifferent_access))

      expect(controller.send(:request_params, :example)).to(include(id: "90"))
    end

    it "returns relationship directly if matching param key" do
      expect(controller.send(:request_params, :book)).to(include(id: "5", title: "Bibliography"))
    end
  end
end
