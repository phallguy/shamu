require "spec_helper"

describe Shamu::Features::Selector do
  it "parses conditions" do
    selector = Shamu::Features::Selector.new(double, "schedule_at" => Time.now)

    expect(selector).to(be_a(Shamu::Features::Selector))
    expect(selector.reject).to(be_falsy)
    expect(selector.conditions.first).to(be_a(Shamu::Features::Conditions::ScheduleAt))
  end

  it "parses reject option" do
    selector = Shamu::Features::Selector.new(double, "reject" => true)

    expect(selector.reject).to(be_truthy)
  end
end