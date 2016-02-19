require "spec_helper"

describe Shamu::Events::Support do
  describe "#event_channel" do
    {
      "Users::UsersService" => "users",
      "Users::ProfileService" => "users/profile",
      "Users::Profiles::ProfilesService" => "users/profiles",
      "Service" => "",
      "Users::Service" => "users"
    }.each do |name, channel|

      it "is #{ channel } for #{ name }" do
        klass = Class.new( Shamu::Services::Service ) do
          include Shamu::Events::Support

          public :event_channel
        end

        allow( klass ).to receive( :name ).and_return name

        expect( klass.new.event_channel ).to eq channel
      end
    end
  end

  describe "event!" do
    hunt( :events_service, Shamu::Events::EventsService )

    let( :klass ) do
      Class.new( Shamu::Services::Service ) do
        include Shamu::Events::Support

        public :event!
      end
    end
    let( :service ) { scorpion.new klass }

    it "publishes message to events_service" do
      expect( events_service ).to receive( :publish )
      service.event! Shamu::Events::Message.new
    end
  end
end