require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::HashedId do
  let(:klass) do
    Class.new do
      include Shamu::Attributes::HashedId

      def initialize(id:)
        @id = id
      end

      attr_accessor :id
    end
  end

  it "returns an obfuscated id value" do
    instance = klass.new(id: 123)

    expect(instance.id).to(eq(123))
    expect(instance.hash_id).not_to(eq(123))
    expect(instance.hash_id).to(be_a(Shamu::Attributes::HashedId::Value))
  end

  it "does not unhash a raw integer" do
    expect(klass.unhash_id(123)).to(eq(123))
  end

  it "unhashes a hashed value" do
    value = klass.hash_id(123)
    expect(klass.unhash_id(value)).to(eq(123))
    expect(value).not_to(eq(123))
  end
end
