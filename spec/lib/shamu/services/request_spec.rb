require "spec_helper"


describe Shamu::Services::Request do
  describe ".model_name" do
    {
      "Users::UserRequest::Create" => "Users::User",
      "Users::UserRequest::New" => "Users::User",
      "Users::UserRequest::Change" => "Users::User",
      "Users::UserRequest::Update" => "Users::User",
      "Users::FavoritesUpdate" => "Users::Favorite",
      "Users::FavoritesCreate" => "Users::Favorite",
      "Users::FavoritesChange" => "Users::Favorite",
      "Users::FavoritesNew" => "Users::Favorite",
      "UserUpdateRequest" => "User"
    }.each do |name, model_name|
      it "formats '#{ name }' as '#{ model_name }'" do
        klass = Class.new( Shamu::Services::Request )
        klass.define_singleton_method :name do
          name
        end

        expect( klass.model_name.name ).to eq model_name
      end
    end
  end

end