require "spec_helper"
require "fileutils"

module FeaturesServiceSpec
  class ProcToggle
    def buy_now?( context, toggle )
      false
    end
  end
end

describe Shamu::Features::FeaturesService do
  let( :config_path ) { File.expand_path( "../features.yml", __FILE__ ) }
  let( :service )     { scorpion.new Shamu::Features::FeaturesService, config_path }
  let( :codec )       { scorpion.new Shamu::Features::ToggleCodec }

  hunt( :session_store, Shamu::Sessions::SessionStore )
  hunt( :env_store, Shamu::Features::EnvStore )

  before( :each ) do
    allow( session_store ).to receive( :fetch ).and_return nil
    allow( env_store ).to receive( :fetch ).and_return nil
  end

  it "lists known features" do
    expect( service.list ).to have_key "shopping/buy_now"
    expect( service.list ).to have_key "uploads/previews"
  end

  it "lists known features by prefix" do
    expect( service.list( "shopping" ) ).to have_key "shopping/buy_now"
    expect( service.list( "shopping" ) ).not_to have_key "uploads/previews"
  end

  # TODO: Figure out how to make this work
  #
  # Listen does something with the threads and doesn't actually fire the change
  # event until after the spec has executed :/.
  #
  # It's been verified to work manually but I'd like to get an automated test in
  # as well.
  #
  # context "with file changes" do
  #   let( :config_path ) { File.expand_path( "../../../../../tmp/#{ SecureRandom.hex( 16 ) }.yml", __FILE__ ) }
  #   it "reloads when any source changes", :focus do
  #     expect( Shamu::Features::Toggle ).to receive( :load ).twice.and_call_original
  #
  #     begin
  #       File.write config_path, {}.to_yaml
  #       service.list
  #       File.write config_path, {}.to_yaml
  #       sleep 1
  #     ensure
  #       File.unlink config_path
  #     end
  #   end
  # end

  context "with session information" do
    let( :packed ) { codec.pack( "shopping/buy_now" => true ) }

    it "reads sticky features" do
      expect( session_store ).to receive( :fetch ).with( "shamu.toggles" ).and_return packed
      expect( service ).not_to receive( :resolve_toggle )

      expect( service.enabled?( "shopping/buy_now" ) ).to eq true
    end

    it "persists sticky context" do
      expect( session_store ).to receive( :set ).with( "shamu.toggles", codec.pack( "shopping/buy_now" => false ) )

      service.enabled?( "shopping/buy_now" )
    end

    it "appends to sticky context" do
      existing_packed = codec.pack( "example" => true )
      expect( session_store ).to receive( :fetch ).with( "shamu.toggles" ).and_return existing_packed
      compbined_packed = codec.pack( "example" => true, "shopping/buy_now" => false )
      expect( session_store ).to receive( :set ).with( "shamu.toggles", compbined_packed )

      service.enabled?( "shopping/buy_now" )
    end
  end

  context "with env information" do
    it "overrides from environment" do
      expect( env_store ).to receive( :fetch ).with( "shopping/buy_now" ).and_return true

      expect( service.enabled?( "shopping/buy_now" ) ).to eq true
    end
  end

  it "is always false for unknown toggles" do
    allow( service.logger ).to receive( :info )
    expect( service.enabled?( "not/yet/set" ) ).to be_falsy
  end

  it "logs when an unknown toggle is checked" do
    expect( service.logger ).to receive( :info ).with /configured/
    service.enabled?( "not/yet/set" )
  end

  it "raises when expired toggle is checked" do
    expect do
      service.enabled?( "uploads/previews" )
    end.to raise_error Shamu::Features::RetiredToggleError, /retired/
  end

end