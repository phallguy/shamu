require "spec_helper"

describe Shamu::Security::PolicyRule do
  describe "#match?" do
    let(:klass)    { Class.new }
    let(:instance) { klass.new }

    let(:rule) do
      Shamu::Security::PolicyRule.new(%i[read write], klass, :yes, nil)
    end

    it "is true for matching action" do
      expect(rule).to(be_match(:read, instance, nil))
    end

    it "is false for unmatched action" do
      expect(rule).not_to(be_match(:examine, instance, nil))
    end

    it "is true for Class match" do
      expect(rule).to(be_match(:read, klass, nil))
    end

    it "is true for instance of Class match" do
      expect(rule).to(be_match(:read, instance, nil))
    end

    it "is true for instance match" do
      rule = Shamu::Security::PolicyRule.new(%i[read write], instance, :yes, nil)
      expect(rule).to(be_match(:read, instance, nil))
    end

    it "is false for Class mismatch" do
      expect(rule).not_to(be_match(:read, Class.new, nil))
    end

    it "is false for instance of Class mismatch" do
      expect(rule).not_to(be_match(:read, Class.new.new, nil))
    end

    it "is false for instance mismatch" do
      rule = Shamu::Security::PolicyRule.new(%i[read write], instance, :yes, nil)
      expect(rule).not_to(be_match(:read, klass.new, nil))
    end

    context "with block" do
      it "invokes block if present" do
        expect do |b|
          Shamu::Security::PolicyRule.new(%i[read write], klass, :yes, b.to_proc).match?(:read, instance, nil)
        end.to(yield_control)
      end
    end
  end
end