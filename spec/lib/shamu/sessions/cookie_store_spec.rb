require "spec_helper"

describe Shamu::Sessions::CookieStore do

  hunt( :cookies, Shamu::Rack::Cookies )
  let( :store ) { scorpion.new Shamu::Sessions::CookieStore }

  it "stores signed cookies" do
    expect( cookies ).to receive( :set ).with( "setting", hash_including( value: /[0-9a-f]{40};example/ ) )
    expect( store ).to receive( :hash_value ).and_call_original

    store.set( "setting", "example" )
  end

  it "reads signed cookies" do
    hashed = store.send( :hash_value, "example" )
    expect( cookies ).to receive( :key? ).with( "setting" ).and_return true
    expect( cookies ).to receive( :get ).with( "setting" ).and_return hashed
    expect( store ).to receive( :verify_hash ).and_call_original

    expect( store.fetch( "setting" ) ).to eq "example"
  end

  it "yields if cookie does not exist" do
    expect( cookies ).to receive( :key? ).with( "setting" ).and_return false

    expect do |b|
      store.fetch( "setting", &b )
    end.to yield_control
  end

  it "ignores unsigned cookies" do
    expect( cookies ).to receive( :key? ).with( "setting" ).and_return true
    expect( cookies ).to receive( :get ).with( "setting" ).and_return "example"
    expect( store ).to receive( :verify_hash ).and_call_original

    expect( store.fetch( "setting" ) ).to eq nil
  end

  it "deletes a cookie" do
    expect( cookies ).to receive( :delete )
    store.delete( "setting" )
  end
end