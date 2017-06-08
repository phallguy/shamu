require "spec_helper"

module AuditingSupportSpec
  class ExampleService < Shamu::Services::Service
    include Shamu::Auditing::Support

    public :audit_request
    public :with_request
  end

  class Change < Shamu::Services::Request
    attribute :name, presence: true
  end
end

describe Shamu::Auditing::Support do
  hunt( :service, Shamu::Auditing::AuditingService )

  let( :example_service ) { scorpion.new AuditingSupportSpec::ExampleService }
  let( :request )         { AuditingSupportSpec::Change.new name: "Penguin" }

  it "audits the request on success" do
    expect( service ).to receive( :commit )

    example_service.audit_request( request ) do |transaction|
    end
  end

  it "skips the request on failure" do
    expect( service ).not_to receive( :commit )
    request.name = nil

    example_service.audit_request( request ) do |transaction|
    end
  end

  it "intuits the audit type from the request class" do
    expect( service ).to receive( :commit ) do |transaction|
      expect( transaction.action ).to eq "change"
    end

    example_service.audit_request( request ) do |request|
    end
  end

  it "wraps with_request" do
    expect( service ).to receive( :commit )

    example_service.with_request( { name: "Example" }, AuditingSupportSpec::Change ) do |request, transaction|
      expect( request ).to be_a AuditingSupportSpec::Change
      expect( transaction ).to be_a Shamu::Auditing::Transaction
    end
  end
end
