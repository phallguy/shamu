require "spec_helper"
require "shamu/services"

module RequestSupportSpec
  class Service < Shamu::Services::Service
    include Shamu::Services::RequestSupport
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
    end
  end
end

describe Shamu::Services::RequestSupport do

  let( :service ) { scorpion.new RequestSupportSpec::Service }

  describe "#request_class" do

    it "finds method specific class" do
      expect( service.request_class( :custom ) ).to be RequestSupportSpec::Request::Custom
    end

    it "falls back to Change" do
      expect( service.request_class( :open ) ).to be RequestSupportSpec::Request::Change
    end

    it "fails if no available class" do
      expect do
        Class.new( Shamu::Services::Service ) do
          include Shamu::Services::RequestSupport
        end.request_class( :change )
      end.to raise_error NameError, /Request/
    end

    it "uses common alias fallback new -> create" do
      expect( service.request_class( :new ) ).to be RequestSupportSpec::Request::Create
    end

    it "uses common alias fallback edit -> update" do
      expect( service.request_class( :edit ) ).to be RequestSupportSpec::Request::Update
    end
  end

end