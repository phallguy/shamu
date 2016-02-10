require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::Validation do
  let( :klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::Validation

      attribute :name, presence: true

      def self.name
        "Example"
      end
    end
  end

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

  it "doesn't clear errors on call to valid?" do
    instance = klass.new( {} )
    instance.validate
    expect( instance ).not_to be_valid

    instance.name = "Something"
    expect( instance ).not_to be_valid
  end

  it "validates methods on validate!" do
    instance = klass.new( {} )
    instance.validate

    expect( instance.errors ).to have_key :name
  end
end