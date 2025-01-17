require "spec_helper"

describe Shamu::Events::InMemory::AsyncService do
  let(:service) { scorpion.new(Shamu::Events::InMemory::AsyncService) }
  let(:message) { Shamu::Events::Message.new }

  describe "#publish" do
    it "adds message to channel" do
      expect do
        service.publish("spec", message)
      end.to(change { service.channel_stats("spec")[:queue_size] })
    end

    it "serializes the message" do
      expect(service).to(receive(:serialize).and_call_original)
      service.publish("spec", message)
    end
  end

  describe "#subscribe" do
    it "receives a message" do
      expect do |b|
        service.subscribe("spec", &b)
        service.publish("spec", message)

        wait_for { service.channel_stats("spec")[:queue_size] }.to(eq(0))
      end.to(yield_control)
    end

    it "deserializes the message" do
      expect(service).to(receive(:deserialize).and_call_original)
      service.publish("spec", message)
      wait_for { service.channel_stats("spec")[:queue_size] }.to(eq(0))
    end
  end
end
