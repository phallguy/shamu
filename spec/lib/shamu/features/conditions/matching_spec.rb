require "spec_helper"

describe Shamu::Features::Conditions::Matching do
  let(:context) { double(Shamu::Features::Context) }
  let(:toggle)  { double(Shamu::Features::Toggle) }

  it "matches if another feature is enabled" do
    condition = scorpion.new(Shamu::Features::Conditions::Matching, "spec/example", toggle)

    expect(context).to(receive(:enabled?).and_return(true))
    expect(condition.match?(context)).to(be_truthy)
  end

  it "doesn't matche if another feature is disabled" do
    condition = scorpion.new(Shamu::Features::Conditions::Matching, "spec/example", toggle)

    expect(context).to(receive(:enabled?).and_return(false))
    expect(condition.match?(context)).to(be_falsy)
  end
end