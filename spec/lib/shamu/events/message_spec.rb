require "spec_helper"

describe Shamu::Events::Message do
  it "generates an ID" do
    expect( Shamu::Events::Message.new.id ).to be_present
  end
end