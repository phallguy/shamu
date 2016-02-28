require "spec_helper"

describe Shamu::Features::ToggleCodec do
  let( :codec ) { Shamu::Features::ToggleCodec.new( SecureRandom.random_bytes( 64 ) ) }

  describe "#pack" do
    subject { codec.pack( "buy_now" => true, "suggestions" => false ) }

    it { is_expected.to match /;/ }
    it { is_expected.to match /[^!]buy_now/ }
    it { is_expected.to match /!suggestions/ }
  end

  describe "#unpack" do
    let( :packed ) { codec.pack( "buy_now" => true, "suggestions" => false ) }

    subject { codec.unpack( packed ) }

    its(["buy_now"])     { is_expected.to eq true }
    its(["suggestions"]) { is_expected.to eq false }
    its(["not/set"])     { is_expected.to be_nil }

    it "handles an empty feature hash" do
      packed = codec.pack( {} )
      expect( codec.unpack( packed ) ).to eq( {} )
    end
  end
end