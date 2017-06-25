require "spec_helper"

describe Shamu::Entities::OpaqueId do

  describe ".opaque_iid" do
    it "encodes the entity path" do
      # Patients::Patient[1]
      expect( Shamu::Entities::OpaqueId.opaque_id( "Patients::Patient[1]" ) ).to eq "UGF0aWVudHM6OlBhdGllbnRbMV0"
    end
  end

  describe ".to_model_id" do
    it "gets the encoded id for a valid opaque id" do
      # Patients::Patient[1]
      expect( Shamu::Entities::OpaqueId.to_model_id( "UGF0aWVudHM6OlBhdGllbnRbMV0" ) ).to eq 1
    end

    it "gets the encoded id for a valid opaque id with mod 4 = 0" do
      expect( Shamu::Entities::OpaqueId.to_model_id( "RW50aXR5TG9va3VwU2VydmljZVNwZWNzOjpFeGFtcGxlWzVd" ) ).to eq 5
    end

    it "is int for raw ids" do
      expect( Shamu::Entities::OpaqueId.to_model_id( "23" ) ).to eq 23
    end
  end

  describe ".opaque_id?" do
    it "recognizes encoded ids" do
      expect( Shamu::Entities::OpaqueId.opaque_id?( "UGF0aWVudHM6OlBhdGllbnRbMV0" ) ).to be_truthy
    end

    it "does not recognize raw numbers" do
      expect( Shamu::Entities::OpaqueId.opaque_id?( "123" ) ).to be_falsy
    end
  end

end
