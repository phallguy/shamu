# frozen_string_literal: true

require "rails_helper"

describe Shamu::Rails::Features, type: :controller do
  controller ActionController::Base do
    public :feature_enabled?

    def show
      render plain: ""
    end
  end

  hunt(:features_service, Shamu::Features::FeaturesService) do
    scorpion.new(Shamu::Features::FeaturesService, File.expand_path("features.yml", __dir__))
  end

  hunt(:session_store, Shamu::Sessions::CookieStore)

  it "resolves toggles" do
    expect(session_store).to(receive(:fetch).and_return(nil))
    allow(session_store).to(receive(:set))

    expect(controller).to(receive(:show)) do
      expect(controller.feature_enabled?("shopping/nux")).to(be_truthy)
      controller.render plain: ""
    end

    get :show, params: { id: 1 }
  end

  it "allows toggles to be overridden by query param" do
    expect(session_store).to(receive(:fetch).and_return(nil))
    allow(session_store).to(receive(:set))

    override = features_service.toggle_codec.pack("shopping/discounts" => true)

    expect(controller).to(receive(:show)) do
      expect(controller.feature_enabled?("shopping/discounts")).to(be_truthy)
      controller.render plain: ""
    end

    get :show, params: { id: 1, Shamu::Features::EnvStore::RACK_PARAMS_KEY => override }
  end
end
