require "spec_helper"
require "shamu/services"

module RequestSupportSpec
  class Service < Shamu::Services::Service
    include Shamu::Services::RequestSupport
    public :extract_params

    def process(params)
      with_request(params, Request::Change) do |request|
        request_hook
        next request.error(:base, "nope") if request.level < 0

        record = OpenStruct.new(request.to_attributes)
        scorpion.fetch(RequestSupportSpec::Entity, record: record)
      end
    end

    def partial_process(params)
      with_partial_request(params, Request::Change) do |request|
        request_hook

        record = OpenStruct.new(request.to_attributes)
        scorpion.fetch(RequestSupportSpec::Entity, record: record)
      end
    end

    def request_hook; end
  end

  module Request
    class Change < Shamu::Services::Request
      attribute :level
      attribute :amount, presence: true
    end

    class Custom < Change
    end

    class Create < Change
    end

    class Update < Change
      attribute :id
    end
  end

  class Entity < Shamu::Entities::Entity
    model :record
    attribute :id, on: :record
    attribute :level, on: :record
    attribute :amount, on: :record
  end

  class UsersService < Shamu::Services::Service
    include Shamu::Services::RequestSupport
  end

  module UserRequest
    class Change < Shamu::Services::Request
    end
  end
end

describe Shamu::Services::RequestSupport do
  let(:service) { scorpion.new(RequestSupportSpec::Service) }

  describe "#request_class" do
    it "finds method specific class" do
      expect(service.request_class(:custom)).to(be(RequestSupportSpec::Request::Custom))
    end

    it "falls back to Change" do
      expect(service.request_class(:open)).to(be(RequestSupportSpec::Request::Change))
    end

    it "fails if no available class" do
      expect do
        Class.new(Shamu::Services::Service) do
          include Shamu::Services::RequestSupport
        end.request_class(:change)
      end.to(raise_error(Shamu::Services::IncompleteSetupError, /Request/))
    end

    it "singularizes service namespace" do
      service = scorpion.new(RequestSupportSpec::UsersService)
      expect(service.request_class(:change)).to(be(RequestSupportSpec::UserRequest::Change))
    end

    it "uses common alias fallback new -> create" do
      expect(service.request_class(:new)).to(be(RequestSupportSpec::Request::Create))
    end

    it "uses common alias fallback edit -> update" do
      expect(service.request_class(:edit)).to(be(RequestSupportSpec::Request::Update))
    end

    it "tries parent service namespace" do
      klass = Class.new(RequestSupportSpec::Service)
      expect(klass.request_class(:change)).to(be(RequestSupportSpec::Request::Change))
    end
  end

  describe "#with_request" do
    let(:request_params) { { level: 1, amount: 5 } }
    let(:service) { scorpion.new(RequestSupportSpec::Service) }

    it "returns a Result" do
      expect(service.process(request_params)).to(be_a(Shamu::Services::Result))
    end

    it "returns validation errors" do
      request_params.delete(:amount)
      expect(service.process(request_params)).not_to(be_valid)
    end

    it "is valid without errors" do
      expect(service.process(request_params)).to(be_valid)
    end

    it "yield with valid params" do
      expect(service).to(receive(:request_hook))
      service.process(request_params)
    end

    it "doesn't yield if params are invalid" do
      request_params.delete(:amount)
      expect(service).not_to(receive(:request_hook))
      service.process(request_params)
    end

    it "captures returned entity into result" do
      result = service.process(request_params)
      expect(result.entity).to(be_a(RequestSupportSpec::Entity))
    end

    it "captures request_params into result" do
      result = service.process(request_params)
      expect(result.request).to(be_a(RequestSupportSpec::Request::Change))
    end
  end

  describe "#with_partial_request" do
    let(:request_params) { { level: 1, amount: 5 } }
    let(:service) { scorpion.new(RequestSupportSpec::Service) }

    it "yields even if params are invalid" do
      request_params.delete(:amount)
      expect(service).to(receive(:request_hook))
      service.partial_process(request_params)
    end

    it "reports errors even if block doesn't check" do
      request_params.delete(:amount)
      result = service.partial_process(request_params)

      expect(result.request.errors).not_to(be_empty)
    end

    it "updates the cache after change" do
      expect(service).to(receive(:recache_entity))

      service.partial_process(request_params)
    end
  end

  describe "#request_for" do
    it "returns request" do
      request = service.request_for(:create)
      expect(request).to(be_a(Shamu::Services::Request))
    end
  end

  describe "#extract_params" do
    it "supports string hash as only param" do
      id, params = service.extract_params({ "id" => 5 }, nil)

      expect(id).to(eq(5))
      expect(params).to(eq(id: 5))
    end

    it "supports string hash as second param" do
      id, params = service.extract_params(9, "id" => 5)

      expect(id).to(eq(9))
      expect(params).to(eq(id: 5))
    end

    it "supports symbol hash as only param" do
      id, params = service.extract_params({ id: 5 }, nil)

      expect(id).to(eq(5))
      expect(params).to(eq(id: 5))
    end

    it "supports symbol hash as second param" do
      id, params = service.extract_params(9, id: 5)

      expect(id).to(eq(9))
      expect(params).to(eq(id: 5))
    end

    it "supports entity as first param" do
      record = OpenStruct.new(id: 5)
      entity = scorpion.fetch(RequestSupportSpec::Entity, record: record)

      id, params = service.extract_params(entity, nil)

      expect(id).to(eq(entity))
      expect(params).to(be_nil)
    end
  end
end
