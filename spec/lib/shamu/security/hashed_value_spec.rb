require "spec_helper"

module HashedValueSpec
  class Codec
    include Shamu::Security::HashedValue

    def initialize( private_key )
      @private_key = private_key
    end

    public :hash_value, :verify_hash
  end
end

describe Shamu::Security::HashedValue do
  let( :codec ) { HashedValueSpec::Codec.new( SecureRandom.random_bytes( 64 ) ) }

  describe "#pack" do
    subject { codec.hash_value( "example" ) }

    it { is_expected.to match /$/ }
    it { is_expected.to match /example/ }
  end

  describe "#unpack" do
    it "gets original value" do
      hashed = codec.hash_value( "example" )
      expect( codec.verify_hash( hashed ) ).to eq "example"
    end

    it "handles an empty feature value" do
      hashed = codec.hash_value( "" )
      expect( codec.verify_hash( hashed ) ).to eq ""
    end

    it "handles an nil feature hash" do
      hashed = codec.hash_value( nil )
      expect( codec.verify_hash( hashed ) ).to eq nil
    end
  end
end