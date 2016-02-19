require "spec_helper"
require "shamu/active_record"

describe Shamu::Events::ActiveRecord::Service do
  let( :message ) { Shamu::Events::Message.new }
  let( :service ) { scorpion.new Shamu::Events::ActiveRecord::Service }


  before( :each ) do
    Shamu::Events::ActiveRecord::Migration.new.migrate( :down )
    Shamu::Events::ActiveRecord::Migration.new.migrate( :up )
  end

  it "prepares the database when initialized" do
    expect( Shamu::Events::ActiveRecord::Service ).to receive( :ensure_records! ).and_call_original
    scorpion.new Shamu::Events::ActiveRecord::Service
  end

  describe "#publish" do
    it "persists the message" do
      expect do
        service.publish( "spec", message )
      end.to change( Shamu::Events::ActiveRecord::Message, :count )
    end

    it "serializes the message" do
      expect( service ).to receive( :serialize ).and_call_original
      service.publish( "spec", message )
    end

    it "creates a new channel on first publish" do
      puts Shamu::Events::ActiveRecord::Channel.all
      expect do
        service.publish "spec", message
      end.to change( Shamu::Events::ActiveRecord::Channel, :count )
    end

    it "re-uses the same channel id for second publish" do
      service.publish "spec", message

      expect do
        service.publish "spec", message
      end.not_to change( Shamu::Events::ActiveRecord::Channel, :count )
    end
  end

  describe "#subscribe" do
    it "receives published messages" do
      expect do |b|
        service.publish "spec", message
        service.subscribe "spec", &b
        service.dispatch "specs", "spec"
      end.to yield_control
    end
  end

  describe "#dispatch" do
    before( :each ) do
      service.publish "spec", message
    end

    it "keeps track of last processed message" do
      runner = Shamu::Events::ActiveRecord::Runner.create!( id: "specs::spec" )

      expect do
        service.dispatch "specs", "spec"
      end.to change { runner.reload.last_processed_id }
    end

    it "keeps track of last run" do
      runner = Shamu::Events::ActiveRecord::Runner.create!( id: "specs::spec" )

      expect do
        service.dispatch "specs", "spec"
      end.to change { runner.reload.last_processed_at }
    end

    it "creates a unique id for each channel" do
      service.dispatch "specs", "spec"

      expect( Shamu::Events::ActiveRecord::Runner.first.id ).to eq "specs::spec"
    end

    it "dispatches new message since last run" do

      service.dispatch "specs", "spec"
      service.publish "spec", Shamu::Events::Message.new

      expect do |b|
        service.subscribe "spec", &b
        service.dispatch "specs", "spec"
      end.to yield_control.once
    end


    it "limits number of messages" do
      5.times do
        service.publish "spec", Shamu::Events::Message.new
      end

      expect do |b|
        service.subscribe "spec", &b
        service.dispatch "specs", "spec", limit: 3
      end.to yield_control.exactly(3)
    end

    it "returns the number of messages dispatched" do
      expect( service.dispatch( "specs", "spec" )["spec"] ).to eq 1
    end
  end

  describe "#channel_stats" do
    before( :each ) do
      service.publish( "spec", message )
    end

    subject { service.channel_stats( "spec" ) }

    its( [:name] )              { is_expected.to eq "spec" }
    its( [:subscribers_count] ) { is_expected.to eq 0 }
    its( [:dispatching] )       { is_expected.to be_falsy }
    its( [:queue_size] )        { is_expected.to eq 1 }

    context "with runner" do
      before( :each ) do
        service.dispatch( "specs", "spec" )
      end

      subject { service.channel_stats( "spec", runner_id: "specs" ) }

      its( [:name] )              { is_expected.to eq "spec" }
      its( [:subscribers_count] ) { is_expected.to eq 0 }
      its( [:dispatching] )       { is_expected.to be_falsy }
      its( [:queue_size] )        { is_expected.to eq 0 }

    end
  end

end