require "spec_helper"

describe Shamu::Auditing::LoggingAuditingService do
  let( :service ) { scorpion.new Shamu::Auditing::LoggingAuditingService }

  it "writes to the logger" do
    expect( service.logger ).to receive( :unknown )

    transaction = Shamu::Auditing::Transaction.new \
      principal: Shamu::Security::Principal.new(user_id: 1),
      action: :change,
      params: { name: "Mr Penguin" }

    transaction.append_entity [ "User", 45 ]

    service.commit transaction
  end

  it "filters protected keys" do
    expect( service.logger ).to receive( :unknown ) do |message|
      expect( message ).not_to match "I'm a secret"
      expect( message ).to match "Mr Penguin"
    end

    transaction = Shamu::Auditing::Transaction.new \
      principal: Shamu::Security::Principal.new(user_id: 1),
      action: :change,
      params: { name: "Mr Penguin", password: "I'm a secret" }

    transaction.append_entity [ "User", 45 ]

    service.commit transaction
  end
end
