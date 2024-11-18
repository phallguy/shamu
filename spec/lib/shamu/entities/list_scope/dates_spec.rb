require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope::Dates do
  let(:klass) do
    Class.new(Shamu::Entities::ListScope) do
      include Shamu::Entities::ListScope::Dates
    end
  end

  it "has a :since attribute" do
    expect(klass.attributes).to(have_key(:since))
  end

  it "has an :until attribute" do
    expect(klass.attributes).to(have_key(:until))
  end

  it "coerces with #to_time if available" do
    expect(Time).to(receive(:instance_method).and_return(true))
    value = double
    expect(value).to(receive(:to_time))

    klass.new(since: value)
  end

  it "includes paging values in to_param" do
    time = Time.now
    expect(klass.new(since: time, until: time).params).to(eq(since: time, until: time))
  end

  it "should not be dated when using defaults" do
    scope = klass.new
    expect(scope.dated?).to(be_falsy)
  end

  it "should not be dated when since is provided" do
    scope = klass.new(since: Time.now)
    expect(scope.dated?).to(be_truthy)
  end

  it "should not be dated when until is provided" do
    scope = klass.new(until: Time.now)
    expect(scope.dated?).to(be_truthy)
  end
end