require "spec_helper"

describe Shamu::Features::EnvStore do
  hunt(:codec, Shamu::Features::ToggleCodec) { scorpion.new(Shamu::Features::ToggleCodec) }

  it "reads from rack header" do
    packed = codec.pack("buy_now" => true)
    env    = {
      "rack.input" => StringIO.new,
      Shamu::Features::EnvStore::RACK_ENV_KEY => packed,
    }
    scorpion.hunt_for(Scorpion::Rack::Env, return: env)

    store = scorpion.fetch(Shamu::Features::EnvStore)
    expect(store.fetch("buy_now")).to(eq(true))
  end

  it "reads from rack params" do
    packed = codec.pack("buy_now" => true)
    env    = {
      "rack.input" => StringIO.new,
      "QUERY_STRING" => "#{Shamu::Features::EnvStore::RACK_PARAMS_KEY}=#{CGI.escape(packed)}",
    }
    scorpion.hunt_for(Scorpion::Rack::Env, return: env)

    store = scorpion.fetch(Shamu::Features::EnvStore)
    expect(store.fetch("buy_now")).to(eq(true))
  end

  it "falls back to env" do
    scorpion.hunt_for(Scorpion::Rack::Env, return: { "rack.input" => StringIO.new })
    store = scorpion.fetch(Shamu::Features::EnvStore)
    key   = store.class.env_key_name("buy_now")

    expect(ENV).to(receive(:key?).with(key).and_return(true))
    expect(ENV).to(receive(:[]).with(key).and_return("false"))

    expect(store.fetch("buy_now")).to(eq(false))
  end

  it "falls back to fall back block" do
    scorpion.hunt_for(Scorpion::Rack::Env, return: { "rack.input" => StringIO.new })
    store = scorpion.fetch(Shamu::Features::EnvStore)

    expect(store.fetch("buy_now") { "yep" }).to(eq("yep"))
  end
end
