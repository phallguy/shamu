require "rails_helper"

describe Shamu::JsonApi::Rails::Pagination do
  it "retains nil value if not set" do
    expect(Shamu::JsonApi::Rails::Pagination.new.number).to(be_nil)
  end

  it "only allows one kind of paging" do
    expect(Shamu::JsonApi::Rails::Pagination.new(size: 1, limit: 1)).not_to(be_valid)
  end
end