require "spec_helper"

module HtmlSanitationSpec
  class Entity < Shamu::Entities::Entity
    include Shamu::Entities::HtmlSanitation

    attribute :name
  end
end

describe Shamu::Attributes::HtmlSanitation do
  let( :entity ) { HtmlSanitationSpec::Entity.new( name: "<b>Bold</b> <p>Name</p>" ) }

  it "removes all HTML by default" do
    expect( entity.name ).to eq "Bold Name"
  end
end