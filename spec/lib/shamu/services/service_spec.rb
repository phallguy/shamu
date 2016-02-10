require "spec_helper"
require "shamu/services"

module ServiceSpec
  class Service < Shamu::Services::Service
    include Shamu::Services::RequestSupport

    def process( params )
      with_request( params, Request::Change ) do |request|
        request_hook
        next error( :base, "nope" ) if request.level < 0

        record = OpenStruct.new( request.to_attributes )
        scorpion.fetch ServiceSpec::Entity, { record: record }, {}
      end
    end

    def request_hook
    end

    public :entity_lookup_list
    public :entity_list
    public :find_by_lookup

    def build_entity( record, records = nil )
      scorpion.fetch ServiceSpec::Entity, { record: record }, {}
    end
  end

  module Request
    class Change < Shamu::Services::Request
      attribute :level
      attribute :amount, presence: true
    end
  end

  class Entity < Shamu::Entities::Entity
    model :record
    attribute :id, on: :record
    attribute :level, on: :record
    attribute :amount, on: :record
  end

  NullEntity = Shamu::Entities::NullEntity.for( Entity )
end

describe Shamu::Services::Service do

  let( :service ) { scorpion.new ServiceSpec::Service }

  describe "#with_request" do
    let( :request_params ) { { level: 1, amount: 5 } }

    it "returns a Result" do
      expect( service.process( request_params ) ).to be_a Shamu::Services::Result
    end

    it "returns validation errors" do
      request_params.delete :amount
      expect( service.process( request_params ) ).not_to be_valid
    end

    it "is valid without errors" do
      expect( service.process( request_params ) ).to be_valid
    end

    it "yield with valid params" do
      expect( service ).to receive( :request_hook )
      service.process( request_params )
    end

    it "doesn't yield if params are invalid" do
      request_params.delete :amount
      expect( service ).not_to receive( :request_hook )
      service.process( request_params )
    end

    it "captures returned entity into result" do
      result = service.process( request_params )
      expect( result.entity ).to be_a ServiceSpec::Entity
    end

    it "captures request_params into result" do
      result = service.process( request_params )
      expect( result.request ).to be_a ServiceSpec::Request::Change
    end
  end

  describe "#entity_list" do
    it "maps each record" do
      expect do |b|
        list = service.entity_list [ double ], &b
        list.to_a
      end.to yield_control
    end

    it "returns an entity list" do
      expect( service.entity_list( [] ) ).to be_a Shamu::Entities::List
    end

    it "invokes build_entity if no transformer provided" do
      expect( service ).to receive( :build_entity ).and_call_original
      list = service.entity_list( [{}] )
      list.first
    end
  end

  describe "#find_by_lookup" do

    it "raises not found if entity is missing" do
      allow( service ).to receive( :lookup ).and_return [ nil ]
      expect do
        service.send :find_by_lookup, 9
      end.to raise_error Shamu::NotFoundError
    end

    it "raises not found if enitty is a NullEntity" do
      entity = Shamu::Entities::NullEntity.for( Shamu::Entities::Entity ).new
      allow( service ).to receive( :lookup ).and_return [ entity ]
      expect do
        service.send :find_by_lookup, 9
      end.to raise_error Shamu::NotFoundError
    end


    it "returns a single entity if founds" do
      expect( service ).to receive( :lookup ).and_return [ double( id: 1 ) ]
      expect( service.send( :find_by_lookup, 1 ) ).to be_present
    end
  end

  describe "#entity_lookup_list" do
    let( :record )  { double id: 5, amount: 17 }
    let( :records ) { [ record ] }

    it "yields for a matching id" do
      expect do |b|
        service.entity_lookup_list( records, [record.id], ServiceSpec::NullEntity, &b )
      end.to yield_control
    end

    it "returns an Entities::List" do
      expect( service.entity_lookup_list( [], [], ServiceSpec::NullEntity ) ).to be_a Shamu::Entities::List
    end

    it "matches on id by default" do
      list = service.entity_lookup_list( records, [record.id], ServiceSpec::NullEntity ) do |r|
        scorpion.fetch ServiceSpec::Entity, { record: r }, {}
      end

      expect( list.first ).to be_present
    end

    it "matches on id with string numbers" do
      list = service.entity_lookup_list( records, [record.id.to_s], ServiceSpec::NullEntity ) do |r|
        scorpion.fetch ServiceSpec::Entity, { record: r }, {}
      end

      expect( list.first ).to be_present
    end

    it "matches on a custom field" do
      list = service.entity_lookup_list( records, [record.amount], ServiceSpec::NullEntity, match: :amount ) do |r|
        scorpion.fetch ServiceSpec::Entity, { record: r }, {}
      end

      expect( list.first ).to be_present
    end

    it "matches with a custom proc" do
      matcher = ->( record ) { record.amount }
      list = service.entity_lookup_list( records, [record.amount], ServiceSpec::NullEntity, match: matcher ) do |r|
        scorpion.fetch ServiceSpec::Entity, { record: r }, {}
      end

      expect( list.first ).to be_present
    end

    it "returns a NullEntity for a non-matching id" do
      list = service.entity_lookup_list( records, [10], ServiceSpec::NullEntity )
      expect( list.first ).to be_a ServiceSpec::NullEntity
      expect( list.first.id ).to eq 10
    end

    it "returns a NullEntity for a non-matching custom field" do
      list = service.entity_lookup_list( records, [192], ServiceSpec::NullEntity, match: :amount )
      expect( list.first ).to be_a ServiceSpec::NullEntity
    end

    it "returns a NullEntity for a non-matching custom matcher" do
      matcher = ->( record ) { record.amount % 17 }

      list = service.entity_lookup_list( records, [192], ServiceSpec::NullEntity, match: matcher )
      expect( list.first ).to be_a ServiceSpec::NullEntity
    end
  end

end