require "spec_helper"
require "shamu/active_record"
require_relative "../active_record_support"

module ActiveRecordCrudSpec
  class FavoriteEntity < Shamu::Entities::Entity
    model :record
    attribute :id, on: :record
    attribute :name, on: :record
    attribute :label, on: :record
  end

  module Request
    class Change < Shamu::Services::Request
      attribute :name
      attribute :label
    end

    class Create < Change
    end

    class Update < Change
      attribute :id
    end

    class Command < Change
      attribute :name
    end

    class Destroy < Change
      attribute :id
    end
  end

  class Service < Shamu::Services::Service
    include Shamu::Services::ActiveRecordCrud
    include Shamu::Services::ObservableSupport

    resource FavoriteEntity, ActiveRecordSpec::Favorite
    define_crud
    define_command :command, ->(request) { lookup_record(request) }

    def lookup_record(request)
      ActiveRecordSpec::Favorite.find_by(name: request.name)
    end
  end

  class FavoriteListScope < Shamu::Entities::ListScope
  end
end

describe Shamu::Services::ActiveRecordCrud do
  use_active_record

  before(:all)  { Shamu::ToModelIdExtension.extend! }

  let(:klass)   { ActiveRecordCrudSpec::Service }
  let(:service) { scorpion.new(klass) }

  before(:each) do
    # Allow generic args to create the entity
    allow(service).to(receive(:authorize!).and_call_original)
  end

  it "includes ActiveRecordService" do
    expect(ActiveRecordCrudSpec::Service).to(include(Shamu::Services::ActiveRecord))
  end

  describe ".resource" do
    it "defines an entity_class" do
      expect(klass.entity_class).to(eq(ActiveRecordCrudSpec::FavoriteEntity))
    end

    it "defines a model_class" do
      expect(klass.model_class).to(eq(ActiveRecordSpec::Favorite))
    end

    it "defines a build_entities method" do
      expect(klass.new.respond_to?(:build_entities, true)).to(be_truthy)
    end

    Shamu::Services::ActiveRecordCrud::DSL_METHODS.each do |method|
      it "defines standard DSL method `#{method}` when passed via `:methods`" do
        expect(klass).to(receive(:"define_#{method}"))
        klass.resource(ActiveRecordCrudSpec::FavoriteEntity, ActiveRecordSpec::Favorite, methods: method)
      end
    end

    it "takes a block defining #build_entities" do
      expect do |b|
        yield_klass = Class.new(klass) do
          resource(ActiveRecordCrudSpec::FavoriteEntity, ActiveRecordSpec::Favorite, &b)
        end

        scorpion.new(yield_klass).create
      end.to(yield_control)
    end

    context "when not used" do
      let(:klass) do
        Class.new(Shamu::Services::Service) do
          include Shamu::Services::ActiveRecordCrud
        end
      end

      it "raises helpful error on entity_class" do
        expect do
          klass.entity_class
        end.to(raise_error(Shamu::Services::IncompleteSetupError))
      end

      it "raises helpful error on model_class" do
        expect do
          klass.model_class
        end.to(raise_error(Shamu::Services::IncompleteSetupError))
      end
    end
  end

  describe ".create" do
    let(:request) { ActiveRecordCrudSpec::Request::Create.new(name: "Example", label: "Books") }

    it "calls Model.new" do
      expect(ActiveRecordSpec::Favorite).to(receive(:new).and_call_original)

      service.create(request)
    end

    it "calls request.apply_to" do
      expect(request).to(receive(:apply_to).and_call_original)
      service.create(request)
    end

    it "returns a Result" do
      expect(service.create(request)).to(be_a(Shamu::Services::Result))
    end

    it "applies request to entity" do
      entity = service.create(request).entity

      expect(entity.name).to(eq("Example"))
      expect(entity.label).to(eq("Books"))
    end

    it "yields if block given" do
      expect do |b|
        yield_klass = Class.new(klass) do
          define_create(&b)
        end

        scorpion.new(yield_klass).create(request)
      end.to(yield_with_args(
               kind_of(ActiveRecord::Base),
               request
             ))
    end

    it "short-circuits if block yields a Services::Result" do
      yield_klass = Class.new(klass) do
        define_create do
          Shamu::Services::Result.new
        end
      end

      service = scorpion.new(yield_klass)

      expect(service).not_to(receive(:build_entity))
      service.create(request)
    end

    it "calls #authorize!" do
      expect(service).to(receive(:authorize!).with(
                           :create,
                           ActiveRecordCrudSpec::FavoriteEntity,
                           kind_of(ActiveRecordCrudSpec::Request::Create)
                         ))

      service.create
    end

    it "is observable" do
      expect do |b|
        service.observe(&b)

        service.create(request)
      end.to(yield_control)
    end
  end

  describe ".change" do
    let(:request) { ActiveRecordCrudSpec::Request::Update.new(name: "Updated Example") }
    let(:entity)  { service.create(name: "Example", label: "Books").entity }

    it "calls Model.find" do
      expect(ActiveRecordSpec::Favorite).to(receive(:find).with(entity.id).and_call_original)
      service.update(entity.id, request)
    end

    it "calls request.apply_to" do
      expect(request).to(receive(:apply_to).and_call_original)
      service.update(entity, request)
    end

    it "backfills missing attributes" do
      expect(request).to(receive(:assign_attributes).with(hash_including(label: "Books")))
      service.update(entity, request)
    end

    it "yields if block given" do
      entity = service.create.entity

      expect do |b|
        yield_klass = Class.new(klass) do
          define_change(:update, &b)
        end

        scorpion.new(yield_klass).update(entity.id, request)
      end.to(yield_with_args(kind_of(ActiveRecord::Base), request))
    end

    it "short-circuits if block yields a Services::Result" do
      entity
      record  = service.class.model_class.all.first
      records = [record]

      expect(records).to(receive(:find).and_return(record))
      expect(record).not_to(receive(:save))

      yield_klass = Class.new(klass) do
        define_update records do
          Shamu::Services::Result.new
        end
      end

      service = scorpion.new(yield_klass)
      service.update(entity.id, request)
    end

    it "calls #authorize!" do
      entity

      expect(service).to(receive(:authorize!).with(
                           :update,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity),
                           kind_of(ActiveRecordCrudSpec::Request::Update)
                         ))

      service.update(entity)
    end

    it "is observable" do
      expect do |b|
        service.observe(&b)

        service.update(entity)
      end.to(yield_control)
    end
  end

  describe ".command" do
    let(:request) { ActiveRecordCrudSpec::Request::Command.new(name: entity.name) }
    let(:entity)  { service.create(name: "Example", label: "Books").entity! }

    it "calls lookup method" do
      expect(service).to(receive(:lookup_record).and_call_original)
      service.command(request)
    end

    it "calls request.apply_to" do
      expect(request).to(receive(:apply_to).and_call_original)
      service.command(request)
    end

    it "yields if block given" do
      expect do |b|
        yield_klass = Class.new(klass) do
          define_command(:command, ->(request) { lookup_record(request) }, &b)
        end

        scorpion.new(yield_klass).command(request)
      end.to(yield_with_args(kind_of(ActiveRecord::Base), request))
    end

    it "short-circuits if block yields a Services::Result" do
      entity
      record = service.class.model_class.all.first
      expect(record).not_to(receive(:save))

      yield_klass = Class.new(klass) do
        define_command :command, ->(_request) { record } do
          Shamu::Services::Result.new
        end
      end

      service = scorpion.new(yield_klass)
      service.command(request)
    end

    it "calls #authorize!" do
      entity

      expect(service).to(receive(:authorize!).with(
                           :command,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity),
                           kind_of(ActiveRecordCrudSpec::Request::Command)
                         ))

      service.command(request)
    end

    it "is observable" do
      expect do |b|
        service.observe(&b)

        service.command(request)
      end.to(yield_control)
    end
  end

  describe ".finders" do
    it "builds #lookup" do
      expect(service).to(respond_to(:lookup))
    end

    it "builds #find" do
      expect(service).to(respond_to(:find))
    end

    it "builds #list" do
      expect(service).to(respond_to(:list))
    end

    context "filtered" do
      let(:klass) do
        Class.new(Shamu::Services::Service) do
          include Shamu::Services::ActiveRecordCrud
          resource ActiveRecordCrudSpec::FavoriteEntity, ActiveRecordSpec::Favorite
        end
      end

      it "excludes unwanted methods" do
        klass.define_finders(except: :list)

        expect(klass.new).to(respond_to(:find))
        expect(klass.new).to(respond_to(:lookup))
        expect(klass.new).not_to(respond_to(:list))
      end

      it "includes only specific methods" do
        klass.define_finders(only: :list)

        expect(klass.new).not_to(respond_to(:find))
        expect(klass.new).not_to(respond_to(:lookup))
        expect(klass.new).to(respond_to(:list))
      end
    end
  end

  describe ".find" do
    let(:entity) { service.create(name: "Example", label: "Books").entity }

    it "calls lookup if no block given" do
      expect(service).to(receive(:lookup).and_return([entity]))
      service.find(1)
    end

    it "yields to block if block given" do
      find_klass = Class.new(klass)
      expect do |b|
        find_klass.define_find do |id|
          b.to_proc.call(id)
          ActiveRecordSpec::Favorite.all.first
        end
        scorpion.new(find_klass).find(entity.id)
      end.to(yield_control)
    end

    it "calls #authorize!" do
      expect(service).to(receive(:authorize!).with(
                           :read,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity)
                         ))

      service.find(entity.id)
    end
  end

  describe ".lookup" do
    let(:entity) { service.create(name: "Example", label: "Books").entity }

    it "uses cached_lookup" do
      expect(service).to(receive(:cached_lookup).and_call_original)
      service.lookup(entity.id)
    end

    it "uses entity_lookup_list" do
      # #create caches the result so bypass the cache
      expect(service).to(receive(:cached_lookup)) do |ids, &block|
        block.call(ids)
      end

      expect(service).to(receive(:entity_lookup_list).and_call_original)
      service.lookup(entity.id)
    end

    it "returns a list of entities" do
      list = service.lookup(entity.id)
      expect(list).to(be_a(Shamu::Entities::List))
      expect(list.size).to(eq(1))
      expect(list.first).to(eq(entity))
    end

    it "returns NullEntitys for missing ids" do
      list = service.lookup(entity.id + 1)
      expect(list.first).to(be_a(Shamu::Entities::NullEntity))
    end

    it "yields to block if given?" do
      expect do |b|
        yield_klass = Class.new(klass) do
          define_lookup(&b)
        end

        scorpion.new(yield_klass).lookup(entity.id)
      end.to(yield_control)
    end

    it "calls #authorize!" do
      expect(service).to(receive(:authorize!).with(
                           :read,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity)
                         ))

      service.lookup(entity.id)
    end

    it "calls #authorize_relation" do
      # #create caches the result so bypass the cache
      expect(service).to(receive(:cached_lookup)) do |ids, &block|
        block.call(ids)
      end

      expect(service).to(receive(:authorize_relation).with(
                           :read,
                           kind_of(ActiveRecord::Relation)
                         ))

      service.lookup(entity.id)
    end
  end

  describe ".list" do
    let!(:entity) { service.create(name: "Example", label: "Books").entity }

    it "returns all the entities" do
      list = service.list
      expect(list).to(be_a(Shamu::Entities::List))
      expect(list.size).to(eq(1))
      expect(list.first).to(eq(entity))
    end

    it "yields if block given" do
      expect do |b|
        yield_klass = Class.new(klass) do
          define_list(&b)
        end

        scorpion.new(yield_klass).list
      end
    end

    it "calls #authorize! for each entity" do
      expect(service).to(receive(:authorize!).with(
                           :read,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity)
                         ))

      service.list.to_a
    end

    it "calls #authorize! to list" do
      expect(service).to(receive(:authorize!).with(
                           :list,
                           ActiveRecordCrudSpec::FavoriteEntity,
                           kind_of(ActiveRecordCrudSpec::FavoriteListScope)
                         ))

      service.list
    end

    it "calls #authorize_relation" do
      expect(service).to(receive(:authorize_relation).with(
                           :read,
                           kind_of(ActiveRecord::Relation),
                           kind_of(ActiveRecordCrudSpec::FavoriteListScope)
                         ))

      service.list
    end
  end

  describe ".destroy" do
    let!(:entity) { service.create(name: "Example", label: "Books").entity }

    it "destroys the record" do
      expect do
        service.destroy(entity).valid!
      end.to(change(ActiveRecordSpec::Favorite, :count).by(-1))
    end

    it "short-circuits if block yields a Services::Result" do
      record = klass.model_class.all.first
      records = [record]

      expect(records).to(receive(:find).and_return(record))

      yield_klass = Class.new(klass) do
        define_destroy :destroy, records do
          Shamu::Services::Result.new
        end
      end

      service = scorpion.new(yield_klass)
      service.destroy(entity)
    end

    it "calls #authorize!" do
      expect(service).to(receive(:authorize!).with(
                           :destroy,
                           kind_of(ActiveRecordCrudSpec::FavoriteEntity),
                           kind_of(ActiveRecordCrudSpec::Request::Destroy)
                         ))

      service.destroy(entity.id)
    end

    it "is observable" do
      expect do |b|
        service.observe(&b)

        service.destroy(entity)
      end.to(yield_control)
    end
  end

  describe ".build_entities" do
    let!(:entity) { service.create(name: "Example", label: "Books").entity }
    let(:entity_class) do
      Class.new(Shamu::Entities::Entity) do
        model :record

        attribute :id
      end
    end
    let(:klass) do
      ec = entity_class
      Class.new(super()) do
        define_build_entities do |records|
          records.map do |record|
            scorpion.fetch(ec, record: record)
          end
        end
        public :build_entities
        public :build_entity
      end
    end

    it "builds an entity from the model record defined by .resource" do
      entity = service.build_entity(ActiveRecordSpec::Favorite.first)
      expect(entity).to(be_a(entity_class))
    end
  end
end
