require "spec_helper"

describe Shamu::Auditing::LoggingAuditingService do
  let( :service ) { scorpion.new Shamu::Auditing::LoggingAuditingService }

  it "writes to the logger" do
    expect( service.logger ).to receive( :unknown )

    transaction = Shamu::Auditing::Transaction.new \
      user_id_chain: [1, 2, 3],
      action: :change,
      changes: { name: "Mr Penguin" }

    transaction.append_entity [ "User", 45 ]

    service.commit transaction
  end
end