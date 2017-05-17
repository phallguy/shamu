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
    public :cached_lookup
    public :lookup_association
    public :lazy_association

    def build_entities( records )
      records.map do |record|
        scorpion.fetch ServiceSpec::Entity, { record: record }, {}
      end
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

  def transformer( &block )
    ->( records ) {
      records.map do |r|
        yield || r
      end
    }
  end


  describe "#entity_list" do
    it "maps each record" do
      expect do |b|
        list = service.entity_list [ double ], &transformer( &b )
        list.to_a
      end.to yield_control
    end

    it "returns an entity list" do
      expect( service.entity_list( [] ) ).to be_a Shamu::Entities::List
    end

    it "invokes build_entity if no transformer provided" do
      expect( service ).to receive( :build_entities ).and_call_original
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
        service.entity_lookup_list( records, [record.id], ServiceSpec::NullEntity, &transformer( &b ) )
      end.to yield_control
    end

    it "returns an Entities::List" do
      expect( service.entity_lookup_list( [], [], ServiceSpec::NullEntity ) ).to be_a Shamu::Entities::List
    end

    it "matches on id by default" do
      list = service.entity_lookup_list( records, [record.id], ServiceSpec::NullEntity ) do |records|
        records.map { |r| scorpion.fetch ServiceSpec::Entity, { record: r }, {} }
      end

      expect( list.first ).to be_present
    end

    it "matches on id with string numbers" do
      list = service.entity_lookup_list( records, [record.id.to_s], ServiceSpec::NullEntity ) do |records|
        records.map { |r| scorpion.fetch ServiceSpec::Entity, { record: r }, {} }
      end

      expect( list.first ).to be_present
    end

    it "matches on a custom field" do
      list = service.entity_lookup_list( records, [record.amount], ServiceSpec::NullEntity, match: :amount ) do |records|
        records.map { |r| scorpion.fetch ServiceSpec::Entity, { record: r }, {} }
      end

      expect( list.first ).to be_present
    end

    it "matches with a custom proc" do
      matcher = ->( record ) { record.amount }
      list = service.entity_lookup_list( records, [record.amount], ServiceSpec::NullEntity, match: matcher ) do |records|
        records.map { |r| scorpion.fetch ServiceSpec::Entity, { record: r }, {} }
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

  describe "#cached_lookup" do

    context "found entities" do
      let( :entities ) do
        Shamu::Entities::List.new [
          ServiceSpec::Entity.new( id: 5, level: 11, amount: "More" ),
          ServiceSpec::Entity.new( id: 11, level: 5, amount: "Less" )
        ]
      end

      let( :records ) do
        [
          OpenStruct.new( id: 5 ),
          OpenStruct.new( id: 11 )
        ]
      end
      let( :transformer ) { ->(record) { entities.get( record.id ) } }
      let( :lookup )      { ->(ids) { ids.map { |id| entities.get( id ) } } }

      it "uses existing entities" do
        service.cached_lookup [ 5 ], &lookup

        expect do |b|
          service.cached_lookup [ 5 ], &b
        end.not_to yield_control
      end

      it "calls build for uncached entities" do
        service.cached_lookup [ 5 ], &lookup

        expect do |b|
          service.cached_lookup [ 5, 11 ] do |missing_ids|
            b.to_proc.call( missing_ids )
            lookup.call( missing_ids )
          end
        end.to yield_with_args( [ 11 ] )
      end

      it "it handles custom matcher" do
        lookup = ->( amounts ) { entities.select { |e| amounts.include?( e.amount ) } }

        service.cached_lookup [ "More" ], match: :amount, &lookup

        expect do |b|
          service.cached_lookup [ "More", "Less" ], match: :amount do |missing_amounts|
            b.to_proc.call( missing_amounts )
            lookup.call( missing_amounts )
          end
        end.to yield_with_args( [ "Less" ] )
      end

      it "it handles custom match block" do
        match = ->( e ) { e.amount.downcase }
        service.cached_lookup ["more"], match: match do |missing_amounts|
          entities.select { |e| missing_amounts.include?( e.amount.downcase ) }
        end

        expect( service.cached_lookup( ["more"], match: match ).first.amount ).to eq "More"
      end

    end

    context "missing entiites" do
      it "caches id" do
        service.cached_lookup( [1] ) do |ids|
          ids.map { |id| Shamu::Entities::NullEntity.for( ServiceSpec::Entity ).new( id: id ) }
        end

        expect( service.cached_lookup( [1] ).first ).to be_a Shamu::Entities::NullEntity
      end

      it "caches custom matcher" do
        service.cached_lookup( [1], match: :level ) do |ids|
          ids.map { |id| Shamu::Entities::NullEntity.for( ServiceSpec::Entity ).new( id: id ) }
        end

        expect( service.cached_lookup( [1], match: :level ).first ).to be_a Shamu::Entities::NullEntity
      end

      it "caches custom match block" do
        match = ->( e ) { e.id * 2 }

        service.cached_lookup( [1], match: match ) do |ids|
          ids.map { |id| Shamu::Entities::NullEntity.for( ServiceSpec::Entity ).new( id: id ) }
        end

        expect( service.cached_lookup( [1], match: match ).first ).to be_a Shamu::Entities::NullEntity
      end
    end
  end

  describe "#lookup_association" do
    before( :each ) do
      allow( service ).to receive( :lookup ) do |*ids|
        ids.map { |id| ServiceSpec::Entity.null_entity.new( id: id ) }
      end
    end

    it "returns nil if id is nil" do
      expect( service.lookup_association( nil, service ) ).to be_nil
    end

    it "yields to get all association links" do
      expect do |b|
        service.lookup_association( 1, service, &b )
      end.to yield_control
    end

    it "finds assocation from cache" do
      service.lookup_association( 1, service ) do
        [ 1, 2 ]
      end

      expect do |b|
        service.lookup_association( 1, service, &b )
      end.not_to yield_control
    end

    it "returns the found entity with no records" do
      result = service.lookup_association( 1, service )
      expect( result ).to be_a ServiceSpec::Entity
    end

    it "returns the found entity with bulk records" do
      result = service.lookup_association( 1, service ) do
        [ 1, 2 ]
      end
      expect( result ).to be_a ServiceSpec::Entity
    end
  end

  describe "#lazy_association" do
    before( :each ) do
      allow( service ).to receive( :lookup ) do |*ids|
        ids.map { |id| ServiceSpec::Entity.null_entity.new( id: id ) }
      end
    end

    it "gets a lazy association" do
      expect( service.lazy_association( 1, service ) ).to be_a Shamu::Services::LazyAssociation
    end


  end
end
