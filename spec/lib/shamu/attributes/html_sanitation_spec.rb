require "spec_helper"

module HtmlSanitationSpec
  class Attrs
    include Shamu::Attributes
    include Shamu::Attributes::HtmlSanitation

    attribute :bio, html: :body
    attribute :name, html: :simple
    attribute :email, html: :none
  end
end

describe Shamu::Attributes::HtmlSanitation do
  context "simple sanitation" do
    let( :entity ) { HtmlSanitationSpec::Attrs.new( name: "<b>Bold</b> <p>Name</p>" ) }

    it "removes non-simple HTML by default" do
      expect( entity.name ).to eq "<b>Bold</b> Name"
    end

    it "exposes original value available via raw attribute" do
      expect( entity.name_raw ).to eq "<b>Bold</b> <p>Name</p>"
    end
  end

  context "none sanitation" do
    let( :entity ) { HtmlSanitationSpec::Attrs.new( email: "<b>Bold</b> <p>Name</p>" ) }

    it "removes all HTML by default" do
      expect( entity.email ).to eq "Bold Name"
    end
  end

  context "body sanitation" do
    let( :entity ) { HtmlSanitationSpec::Attrs.new( bio: "<script>alert('Hacked')</script><h2>Title</h2>" ) }

    it "only removes illegal HTML" do
      expect( entity.bio ).to eq "<h2>Title</h2>"
    end
  end
end