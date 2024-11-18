require "spec_helper"
require "shamu/rack"

describe Shamu::Rack::Cookies do
  let(:headers) { {} }
  let(:env)     { {} }
  let(:cookies) { Shamu::Rack::Cookies.new(env) }

  it "sets a cookie" do
    cookies.set(:id, "123")
    expect(cookies.get("id")).to(eq("123"))
  end

  it "gets a cookie" do
    env["HTTP_COOKIE"] = "remember_me=true; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"
    expect(cookies.get("remember_me")).to(eq("true"))
  end

  it "overwrites existing cookie" do
    env["HTTP_COOKIE"] = "favorite=batman"
    cookies.set("favorite", "superman")

    expect(cookies.get("favorite")).to(eq("superman"))
  end

  describe "#apply" do
    it "adds new cookies" do
      cookies.set("name", "phallguy")
      cookies.apply!(headers)

      expect(headers["set-cookie"]).to(match(/phallguy/))
    end

    it "removes old cookies" do
      env["HTTP_COOKIE"] = "remember_me=true"

      cookies.delete("remember_me")
      cookies.apply!(headers)

      expect(headers["set-cookie"]).to(match(/remember_me=;/))
    end
  end
end