require "rails_helper"

module LoadEntitySpec
  class Service < Shamu::Services::Service
    include Shamu::Security::Support
    include Shamu::Services::RequestSupport

    def find( id )
      scorpion.fetch ExampleEntity, id: id
    end

    def list( params = nil )
      Shamu::Entities::List.new [ find( 1 ) ]
    end

    def authorize!( * )
    end
  end

  class ExampleEntity < Shamu::Entities::Entity
    attribute :id
  end

  module Request
    class Change < Shamu::Services::Request
      attribute :id
    end
  end
end

describe Shamu::Rails::Entity, type: :controller do
  hunt( :example_service, LoadEntitySpec::Service ) { scorpion.new LoadEntitySpec::Service }

  controller ActionController::Base do
    service :examples_service, LoadEntitySpec::Service
    entity LoadEntitySpec::ExampleEntity

    def show
      render plain: ""
    end

    def index
      render plain: ""
    end

    def new
      render plan: ""
    end

    def create
      example_request
      render plain: ""
    end

  end

  before( :each ) do
    controller.params[:action] = "show"
  end

  it "adds an #example method" do
    expect( controller.respond_to?( :example, true ) ).to be_truthy
  end

  it "loads the entity from the service" do
    expect( example_service ).to receive( :find )
    controller.params[:id] = 1
    controller.send :example
  end

  it "adds an #example_request method" do
    expect( controller.respond_to?( :example_request, true ) ).to be_truthy
  end

  it "builds a request from the service" do
    expect( example_service ).to receive( :request_for )
    controller.send :example_request
  end

  it "gets params from example_params" do
    expect( example_service ).to receive( :request_for ).and_return Shamu::Services::Request.new
    expect( controller ).to receive( :example_params )

    controller.send :example_request
  end

  it "loads the entity before the request" do
    expect( controller ).to receive( :example ).and_call_original
    get :show, params: { id: 1 }
  end

  it "invokes list for index types" do
    expect( controller ).to receive( :examples ).and_call_original
    get :index
  end

  it "authorizes action for entity request" do
    expect( example_service ).to receive( :authorize! )

    post :create
  end

  it "doesn't load entity on create actions" do
    expect( controller ).not_to receive( :example )

    post :create
  end

  context "only some actions" do
    controller ActionController::Base do
      service :example_service, LoadEntitySpec::Service
      entity LoadEntitySpec::ExampleEntity, only: :show

      def show
        render plain: ""
      end

      def new
        render plain: ""
      end

      def create
        render plain: ""
      end
    end

    it "loads on show" do
      expect( controller ).to receive( :example )
      get :show, params: { id: 1 }
    end

    it "doesn't load on new" do
      expect( controller ).not_to receive( :example )
      post :create
      get :new
    end
  end

  context "except some actions" do
    controller ActionController::Base do
      service :example_service, LoadEntitySpec::Service
      entity LoadEntitySpec::ExampleEntity, except: :show

      def show
        render plain: ""
      end

      def new
        render plain: ""
      end

      def create
        render plain: ""
      end
    end

    it "loads on show" do
      expect( controller ).not_to receive( :example )
      get :show, params: { id: 1 }
    end

    it "doesn't load on new" do
      expect( controller ).not_to receive( :example )
      get :new
    end
  end

end
