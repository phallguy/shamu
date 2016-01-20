require "spec_helper"
require "shamu/errors"

describe Shamu::Errors do
  let( :errors ) { Shamu::Errors.new( self ) }

  it "has no errors for valid attributes" do
    expect( errors.include?( :something_valid ) ).to be_falsy
  end

  it "is empty? when no reported errors" do
    expect( errors ).to be_empty
  end

  it "gets all errors using attribute key" do
    errors.add( :fail, "Nope" )
    expect( errors[:fail] ).not_to be_empty
  end

  it "is not empty when errors are reported" do
    errors.add( :fail, "So sad" )
    expect( errors ).not_to be_empty
  end
end