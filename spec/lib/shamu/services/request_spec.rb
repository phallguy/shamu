require "spec_helper"


describe Shamu::Services::Request do
  describe ".model_name" do
    {
      "Users::UserRequest::Create" => "Users::User",
      "Users::UserRequest::New" => "Users::User",
      "Users::UserRequest::Change" => "Users::User",
      "Users::UserRequest::Update" => "Users::User",
      "Users::Request::Change" => "Users::User",
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

  describe "#apply_to" do
    let( :klass ) do
      Class.new( Shamu::Services::Request ) do
        attribute :name
        attribute :label
      end
    end
    let( :request ) { klass.new name: "Example" }

    it "returns the model" do
      model = double
      expect( Shamu::Services::Request.new.apply_to( model ) ).to be model
    end

    it "assigns attributes that have been set" do
      model = double( name: "", label: "" )
      expect( model ).to receive( :name= ).with( any_args )

      request.apply_to( model )
    end

    it "skips attributes that haven't been set" do
      model = double( name: "", label: "" )
      expect( model ).not_to receive( :label= )

      request.apply_to( model )
    end
  end

end