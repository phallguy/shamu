require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope::Paging do
  let( :klass ) do
    Class.new( Shamu::Entities::ListScope ) do
      include Shamu::Entities::ListScope::Paging
    end
  end

  it "has a :page attribute" do
    expect( klass.attributes ).to have_key :page
  end

  it "has a :per_page attribute" do
    expect( klass.attributes ).to have_key :per_page
  end

  it "has a :default_per_page" do
    expect( klass.attributes ).to have_key :default_per_page
  end

  it "uses default_per_page if not per_page set" do
    expect( klass.new.per_page ).to eq 25
  end

  it "includes paging values in to_param" do
    expect( klass.new.params ).to eq page: nil, per_page: 25
  end

  it "should not be paged if using defaults" do
    scope = klass.new
    expect( scope.paged? ).to be_falsy
  end

  it "should be paged when attribute specified" do
    scope = klass.new page: 1
    expect( scope.paged? ).to be_truthy
  end

end