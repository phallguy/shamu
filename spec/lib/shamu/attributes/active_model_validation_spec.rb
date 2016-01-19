require "spec_helper"
require "shamu/attributes"
require "shamu/attributes/active_model_validation"

describe Shamu::Attributes::ActiveModelValidation do

  let( :klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::ActiveModelValidation

      attribute :name, presence: true

      def self.name
        "Example"
      end
    end
  end

  it "doesn't clear errors on call to valid?" do
    instance = klass.new( {} )
    instance.validate
    expect( instance ).not_to be_valid

    instance.name = "Something"
    expect( instance ).not_to be_valid
  end

  it "validates methods on validate!" do
    instance = klass.new( {} )
    instance.validate

    expect( instance.errors ).to have_key :name
  end
end