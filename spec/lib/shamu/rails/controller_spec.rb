require "rails_helper"

module ControllerSpec
  class Service < Shamu::Services::Service
  end

  class SecureService < Shamu::Services::Service
    include Shamu::Security::Support
  end
end

describe Shamu::Rails::Controller, type: :controller do
  controller ActionController::Base do
    service :example_service, ControllerSpec::Service
    service :secure_service, ControllerSpec::SecureService

    public :services, :secure_services, :permit?

    def show
      render json: "{}"
    end
  end

  describe ".service" do
    it "makes the service available" do
      expect(controller.respond_to?(:example_service, true)).to(be_truthy)
      expect(controller.send(:example_service)).to(be_a(ControllerSpec::Service))
    end
  end

  describe "#services" do
    it "includes all the services" do
      expect(controller.services).to(include(kind_of(ControllerSpec::Service)))
      expect(controller.services).to(include(kind_of(ControllerSpec::SecureService)))
    end
  end

  describe "#secure_services" do
    it "includes only the secure services" do
      expect(controller.secure_services).not_to(include(kind_of(ControllerSpec::Service)))
      expect(controller.secure_services).to(include(kind_of(ControllerSpec::SecureService)))
    end

    it "gets security context from current_user" do
      expect(controller).to(receive(:current_principal_id).at_least(:once).and_return(945))

      expect(controller).to(receive(:show)) do
        expect(scorpion.fetch(Shamu::Security::Principal).principal_id).to(eq(945))
        controller.render(plain: "")
      end

      get :show, params: { id: 5 }
    end
  end

  describe ".services" do
    it "includes all the service names" do
      expect(controller.class.services).to(match(%i[example_service secure_service]))
    end
  end

  describe "#permit?" do
    it "is true if any of the secure_services permit the requested behavior" do
      expect(controller.send(:secure_service)).to(receive(:permit?).and_return(:yes))
      expect(controller).to(be_permitted_to(:read, :something))
    end

    it "is false if none of the secure_services permit the requested behavior" do
      expect(controller.send(:secure_service)).to(receive(:permit?).and_return(false))
      expect(controller).not_to(be_permitted_to(:read, :something))
    end
  end
end
