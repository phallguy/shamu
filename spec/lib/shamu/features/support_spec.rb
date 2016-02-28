require "spec_helper"

describe Shamu::Features::FeaturesService do
  hunt( :features_service, Shamu::Features::FeaturesService )
  let( :klass ) do
    Class.new( Shamu::Services::Service ) do
      include Shamu::Features::Support

      public :when_feature
    end
  end
  let( :service ) { scorpion.new klass }

  it "executes the block if enabled" do
    allow( features_service ).to receive( :enabled? ).and_return true

    expect do |b|
      service.when_feature( "example", &b )
    end.to yield_control
  end

  it "doesn't execute if not enabled" do
    allow( features_service ).to receive( :enabled? ).and_return false

    expect do |b|
      service.when_feature( "example", &b )
    end.not_to yield_control
  end

  it "can override enabled" do
    allow( features_service ).to receive( :enabled? ).and_return false

    expect do |b|
      service.when_feature( "example", override: true, &b )
    end.to yield_control
  end

  it "can override disabled" do
    allow( features_service ).to receive( :enabled? ).and_return true

    expect do |b|
      service.when_feature( "example", override: false, &b )
    end.not_to yield_control
  end
end