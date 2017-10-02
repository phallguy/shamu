require "spec_helper"


describe Shamu::Services::ObservedRequest do
  let( :request ) { double Shamu::Services::Request }
  let( :success ) { double Shamu::Services::Result, valid?: true }
  let( :failure ) { double Shamu::Services::Result, valid?: false }

  let( :action ) do
    Shamu::Services::ObservedRequest.new request: request
  end

  before( :each ) do
    [ success, failure ].each do |result|
      allow( result ).to receive( :join )
    end
  end

  describe "#complete" do
    context "#on_canceled" do
      it "is invoked when canceled" do
        expect do |b|
          action.on_canceled( &b )
          action.complete success, true
        end.to yield_control
      end

      it "is not invoked if not canceled" do
        expect do |b|
          action.on_canceled( &b )
          action.complete success, false
        end.not_to yield_control
      end

      it "joins results" do
        result = double Shamu::Services::Result
        expect( failure ).to receive( :join ).with( result )
        action.on_canceled do |_|
          result
        end

        action.complete failure, true
      end
    end
  end
end
