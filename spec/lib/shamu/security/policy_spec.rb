require "spec_helper"

describe Shamu::Security::Policy do
  let( :principal ) { Shamu::Security::Principal.new }
  let( :roles )     { [] }
  let( :policy )    { klass.new principal: principal, roles: roles }
  let( :klass ) do
    Class.new( Shamu::Security::Policy ) do
      role :super_user, inherits: :admin
      role :admin, inherits: :user
      role :user

      public :in_role?, :add_rule, :rules, :permit, :deny, :when_elevated,
             :alias_action, :expand_aliases
    end
  end

  describe "#authorize" do
    it "raises when not permitted" do
      allow( policy ).to receive( :permit? ).and_return false

      expect do
        policy.authorize! :read, :stuff
      end.to raise_error Shamu::Security::AccessDeniedError
    end

    it "raises when maybe permitted" do
      allow( policy ).to receive( :permit? ).and_return :maybe

      expect do
        policy.authorize! :read, :stuff
      end.to raise_error Shamu::Security::AccessDeniedError
    end

    it "returns the authorized resource" do
      allow( policy ).to receive( :permit? ).and_return :yes
      resource = double
      expect( policy.authorize!( :read, resource ) ).to be resource
    end
  end

  describe "#in_role?" do
    it "is true for :user when principal is signed in" do
      allow( policy.principal ).to receive( :user_id ).and_return 1

      expect( policy.in_role?( :user ) ).to be_truthy
    end

    it "is false for :user when principal is anonymous" do
      allow( policy.principal ).to receive( :user_id ).and_return nil

      expect( policy.in_role?( :user ) ).to be_falsy
    end

    it "is true for an explicitly assigned role" do
      roles << :admin
      expect( policy.in_role?( :admin ) ).to be_truthy
    end

    it "is true for an implicitly assigned role" do
      roles << :super_user
      expect( policy.in_role?( :admin ) ).to be_truthy
    end

    it "is false for empty roles list" do
      expect( policy.in_role? ).to be_falsy
    end
  end

  describe "#permit?" do
    let( :rule )         { double Shamu::Security::PolicyRule }
    let( :second_rule )  { double Shamu::Security::PolicyRule }
    before( :each ) do
      allow( policy ).to receive( :rules ).and_return [ rule, second_rule ]

      [ rule, second_rule ].each do |r|
        allow( r ).to receive( :match? ).and_return false
      end
    end

    it "permits with matching rule" do
      allow( rule ).to receive( :match? ).and_return true
      allow( rule ).to receive( :result ).and_return :yes

      expect( policy.permit?( :do, :stuff ) ).to be_truthy
    end

    it "denies if no matching rule" do
      expect( policy.permit?( :do, :stuff ) ).to be_falsy
    end

    it "denies if expliclitly denied after permit" do
      expect( rule ).to receive( :match? ).and_return true
      expect( rule ).to receive( :result ).and_return false

      allow( second_rule ).to receive( :match? ).and_return true
      allow( second_rule ).to receive( :result ).and_return :yes

      expect( policy.permit?( :do, :stuff ) ).to be_falsy
    end

    it "fails when testing an ActiveRecord resource" do
      expect do
        policy.permit? :check, Class.new( ActiveRecord::Base )
      end.to raise_error Shamu::Security::NoActiveRecordPolicyChecksError
    end
  end

  describe "#permit" do
    it "adds a :maybe rule when defined within #when_elevated" do
      allow( policy ).to receive( :permissions ) do
        policy.when_elevated do
          policy.permit :do, :stuff
        end
      end

      expect( policy.rules.first.result ).to eq :maybe
    end
  end

  describe "#add_rule" do
    before( :each ) do
      allow( policy ).to receive( :permissions )
    end

    it "expands action aliases" do
      expect( policy ).to receive( :expand_aliases ).and_call_original
      policy.add_rule [ :do ], :stuff, :yes
    end

    it "pushes rule to front" do

      policy.add_rule [ :do ], :stuff, :one
      policy.add_rule [ :do ], :stuff, :two

      expect( policy.rules.first.result ).to eq :two
    end
  end

  describe "#expand_aliases" do
    before( :each ) do
      policy.alias_action :show, :list, to: :read
      policy.alias_action :index, to: :list
    end

    it "includes explicit actions" do
      expect( policy.expand_aliases( [ :read ] ) ).to include :read
    end

    it "includes aliases" do
      expect( policy.expand_aliases( [ :read ] ) ).to include :show
    end

    it "includes aliases of aliases" do
      expect( policy.expand_aliases( [ :read ] ) ).to include :index
    end
  end
end