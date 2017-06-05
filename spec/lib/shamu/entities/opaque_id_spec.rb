require "spec_helper"

describe Shamu::Entities::OpaqueId do

  describe ".to_model_id" do
    it "gets the encoded id for a valid opaque id" do
      # Patients::Patient[1]
      expect( Shamu::Entities::OpaqueId.to_model_id( "::UGF0aWVudHM6OlBhdGllbnRbMV0=" ) ).to eq 1
    end

    it "is int for raw ids" do
      expect( Shamu::Entities::OpaqueId.to_model_id( "23" ) ).to eq 23
    end
  end

  describe ".opaque_id?" do
    it "recognizes encoded ids" do
      expect( Shamu::Entities::OpaqueId.opaque_id?( "::UGF0aWVudHM6OlBhdGllbnRbMV0=" ) ).to be_truthy
    end

    it "does not recognize raw numbers" do
      expect( Shamu::Entities::OpaqueId.opaque_id?( "123" ) ).to be_falsy
    end

    it "does not recognize base64 encoded" do
      expect( Shamu::Entities::OpaqueId.opaque_id?( "UGF0aWVudHM6OlBhdGllbnRbMV0=" ) ).to be_falsy
    end
  end

end
