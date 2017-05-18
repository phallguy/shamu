require "spec_helper"
require "active_model"

describe Shamu::JsonApi::Response do
  let( :context )  { Shamu::JsonApi::Context.new }
  let( :response ) { Shamu::JsonApi::Response.new context }

  it "uses presenter if given" do
    presenter = double
    expect( presenter ).to receive( :new ) do |resource, builder|
      instance = Shamu::JsonApi::Presenter.new resource, builder

      expect( instance ).to receive( :present ) do
        builder.identifier :response, 9
      end

      instance
    end

    response.resource double, presenter
  end

  it "expects a block if no presenter" do
    expect do
      response.resource double
    end.to raise_error Shamu::JsonApi::NoPresenter
  end

  it "appends included resources" do

    response.resource double do |builder|
      builder.identifier :example, 4
      builder.relationship :parent do |rel|
        rel.identifier :suite, 10
        rel.include_resource double do |res|
          res.identifier :suite, 10
        end
      end
    end

    expect( response.compile ).to include included: [ hash_including( type: "suite" ) ]
  end

  it "includes errors" do
    response.error NotImplementedError.new

    expect( response.compile ).to include errors: [ hash_including( code: "not_implemented" ) ]
  end

  it "writes validation errors" do
    klass = Class.new do
      include ActiveModel::Validations

      attr_reader :title
      validates :title, presence: true

      validate :general_problem

      def general_problem
        errors.add :base, "nope"
      end
    end

    allow( klass ).to receive( :name ).and_return "Example"
    record = klass.new
    record.valid?

    response.validation_errors record.errors
    expect( response.compile ).to include errors: include( hash_including( source: { pointer: "/data/attributes/title" } ) ) # rubocop:disable Metrics/LineLength
    expect( response.compile ).to include errors: include( hash_including( source: { pointer: "/data" } ) )
  end
end
