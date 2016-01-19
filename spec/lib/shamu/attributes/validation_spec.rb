require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::Validation do
  it "forwards unused options to .validates method" do
    TestClass = Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Validation
    end

    expect( TestClass ).to receive( :validates ).with( :name, presence: true )
    class TestClass
      attribute :name, on: :user, presence: true
    end
  end
end