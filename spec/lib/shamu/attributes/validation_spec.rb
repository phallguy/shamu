require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::Validation do
  let(:klass) do
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

    expect(TestClass).to(receive(:validates).with(:name, presence: true))
    class TestClass
      attribute :name, on: :user, presence: true
    end
  end

  it "doesn't clear errors on call to valid?" do
    instance = klass.new({})
    instance.validate
    expect(instance).not_to(be_valid)

    instance.name = "Something"
    expect(instance).not_to(be_valid)
  end

  it "validates methods on validate" do
    instance = klass.new({})
    instance.validate

    expect(instance.errors).to(have_key(:name))
  end

  it "validates on first call to valid?" do
    instance = klass.new({})
    expect(instance).to(receive(:validate).once.and_call_original)
    instance.valid?
    instance.valid?
  end

  it "supports shamu validators with simple hash names" do
    nested = Class.new(klass) do
      attribute :nested, valid: true
    end

    expect(nested.validators).to(include(Shamu::Attributes::Validators::ValidValidator))
  end
end
