require "spec_helper"

module AuditingSupportSpec
  class ExampleService < Shamu::Services::Service
    include Shamu::Auditing::Support

    public :audit_request
  end

  class Change < Shamu::Services::Request
    attribute :name, presence: true
  end
end

describe Shamu::Auditing::Support do
  hunt( :service, Shamu::Auditing::AuditingService )
  let( :example_service ) { scorpion.new AuditingSupportSpec::ExampleService }

  it "audits the request on success" do
    expect( service ).to receive( :commit )

    example_service.audit_request( { name: "Penguin" }, AuditingSupportSpec::Change ) do |request, transaction|
    end
  end

  it "skips the request on failure" do
    expect( service ).not_to receive( :commit )

    example_service.audit_request( {}, AuditingSupportSpec::Change ) do |request, transaction|
    end
  end

  it "intuits the audit type from the request class" do
    expect( service ).to receive( :commit ) do |transaction|
      expect( transaction.action ).to eq "change"
    end

    example_service.audit_request( { name: "Penguin" }, AuditingSupportSpec::Change ) do |request, transaction|
    end
  end
end