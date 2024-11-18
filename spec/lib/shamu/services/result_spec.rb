require "spec_helper"
require "shamu/services"

describe Shamu::Services::Result do
  it "detects Request in sources" do
    request = Shamu::Services::Request.new
    result  = Shamu::Services::Result.new(request)

    expect(result.request).to(eq(request))
  end

  it "detects Entity in sources" do
    entity = Shamu::Entities::Entity.new
    result = Shamu::Services::Result.new(entity)

    expect(result.entity).to(eq(entity))
  end

  it "copies errors from source" do
    request = Shamu::Services::Request.new
    request.errors.add(:base, "something failed")
    result = Shamu::Services::Result.new(request)

    expect(result).not_to(be_valid)
  end

  it "doesn't set request if not found" do
    result = Shamu::Services::Result.new
    expect(result.request).to(be_nil)
  end

  it "doesn't set entity if not found" do
    result = Shamu::Services::Result.new
    expect(result.entity).to(be_nil)
  end

  describe "#value!" do
    it "raises an error if not valid" do
      result = Shamu::Services::Result.new
      result.errors.add(:base, :whatever)

      expect do
        result.value!
      end.to(raise_error(Shamu::Services::ServiceRequestFailedError))
    end

    it "returns #value if valid" do
      result = Shamu::Services::Result.new(:one)

      expect(result.value!).to(eq(:one))
    end
  end

  describe "#entity!" do
    it "raises an error if not valid" do
      entity = Shamu::Entities::Entity.new
      result = Shamu::Services::Result.new(entity)
      result.errors.add(:base, :whatever)

      expect do
        result.entity!
      end.to(raise_error(Shamu::Services::ServiceRequestFailedError))
    end

    it "returns #entity if valid" do
      entity = Shamu::Entities::Entity.new
      result = Shamu::Services::Result.new(entity)

      expect(result.entity!).to(be(entity))
    end
  end
end
