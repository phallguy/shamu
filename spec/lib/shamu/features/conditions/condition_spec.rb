require "spec_helper"

describe Shamu::Features::Conditions do
  it "finds the proper condition" do
    condition = Shamu::Features::Conditions::Condition.create("schedule_at", Time.now, double)
    expect(condition).to(be_a(Shamu::Features::Conditions::ScheduleAt))
  end
end