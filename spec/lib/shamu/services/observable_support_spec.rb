require "spec_helper"
require "shamu/active_record"

class ObservableService < Shamu::Services::Service
  include Shamu::Services::ObservableSupport

  public :with_observers, :notify_observers
end

describe Shamu::Services::ObservableSupport do
  let(:service) { scorpion.new(ObservableService) }
  let(:request) { Shamu::Services::Request.new }
  let(:action)  { Shamu::Services::ObservedRequest.new(request: request) }

  describe "#notify_observers" do
    it "notifies all registered observers" do
      expect do |b|
        service.observe(&b)
        service.notify_observers(action)
      end.to(yield_control)
    end
  end

  describe "#with_observers" do
    it "notifies observers" do
      expect do |b|
        service.observe(&b)
        service.with_observers(request) do |req|
          Shamu::Services::Result.new(request: req)
        end
      end.to(yield_control)
    end

    it "does not yield if action was canceled" do
      expect do |b|
        service.observe do |a|
          a.request_cancel(Shamu::Services::Result.new)
        end
        service.with_observers(request, &b)
      end.not_to(yield_control)
    end

    it "reports an error indicating the request was canceled" do
      service.observe do |a|
        a.request_cancel(Shamu::Services::Result.new)
      end

      result = service.with_observers(request)

      expect(result).not_to(be_valid)
      expect(result.errors.full_messages).to(include(/canceled/))
    end
  end
end
