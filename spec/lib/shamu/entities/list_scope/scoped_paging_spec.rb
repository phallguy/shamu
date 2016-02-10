require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope::Paging do
  let( :klass ) do
    Class.new( Shamu::Entities::ListScope ) do
      include Shamu::Entities::ListScope::ScopedPaging
    end
  end

  it "has a :page attribute" do
    expect( klass.attributes ).to have_key :page
  end

  it "has a :page.number attribute" do
    expect( klass.new.page.class.attributes ).to have_key :number
  end

  it "has a :page.size attribute" do
    expect( klass.new.page.class.attributes ).to have_key :size
  end

  it "has a :page.default_size attribute" do
    expect( klass.new.page.class.attributes ).to have_key :default_size
  end

  it "includes paging values in to_param" do
    expect( klass.new.params ).to eq page: { number: nil, size: 25 }
  end

  it "should be paged when attribute specified" do
    scope = klass.new page: { number: 1 }
    expect( scope.scoped_page? ).to be_truthy
  end

  it "should not be paged if using defaults" do
    scope = klass.new
    expect( scope.scoped_page? ).to be_falsy
  end
end