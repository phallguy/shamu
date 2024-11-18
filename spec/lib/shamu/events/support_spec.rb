require "spec_helper"

module EventsSupportSpec
  class Service < Shamu::Services::Service
    include Shamu::Events::Support

    public :event!
  end

  module Events
    class Boom < Shamu::Events::Message
      attribute :name
    end
  end
end

describe Shamu::Events::Support do
  describe "#event_channel" do
    {
      "Users::UsersService" => "users",
      "Users::ProfileService" => "users/profile",
      "Users::Profiles::ProfilesService" => "users/profiles",
      "Service" => "",
      "Users::Service" => "users",
    }.each do |name, channel|
      it "is #{channel} for #{name}" do
        klass = Class.new(Shamu::Services::Service) do
          include Shamu::Events::Support

          public :event_channel
        end

        allow(klass).to(receive(:name).and_return(name))

        expect(klass.new.event_channel).to(eq(channel))
      end
    end
  end

  describe "event!" do
    hunt(:events_service, Shamu::Events::EventsService)

    let(:service) { scorpion.new(EventsSupportSpec::Service) }

    it "publishes message to events_service" do
      expect(events_service).to(receive(:publish))
      service.event!(Shamu::Events::Message.new)
    end

    it "creates message from attributes" do
      expect(events_service).to(receive(:publish))
      service.event!(:boom, name: "Me")
    end
  end
end
