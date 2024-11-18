require "spec_helper"
require "shamu/services"
require "shamu/services/active_record"

describe Shamu::Services::ActiveRecord do
  use_active_record

  let(:klass) do
    Class.new(Shamu::Services::Service) do
      include Shamu::Services::ActiveRecord
      public :wrap_not_found, :scope_relation, :with_transaction
    end
  end
  let(:service) { scorpion.new(klass) }

  describe "#wrap_not_found" do
    it "re-raises AR not found as shamu not found" do
      expect do
        service.wrap_not_found do
          raise ActiveRecord::RecordNotFound
        end
      end.to(raise_error(Shamu::NotFoundError))
    end
  end

  describe "#scope_relation" do
    it "short-circuits if no relation" do
      expect(service.scope_relation(nil, nil)).to(be_nil)
    end

    it "invokes by_list_scope if available" do
      scope    = ActiveRecordSpec::FavoriteScope.new
      relation = ActiveRecordSpec::Favorite.all

      expect(relation).to(receive(:by_list_scope))
      service.scope_relation(relation, scope)
    end

    it "it raises helpful error if relation isn't scopable" do
      scope    = ActiveRecordSpec::FavoriteScope.new
      relation = ActiveRecordSpec::Favorite.all

      expect(relation).to(receive(:respond_to?).and_return(false))

      expect do
        service.scope_relation(relation, scope)
      end.to(raise_error(/by_list_scope/))
    end
  end

  describe "#with_transaction" do
    it "returns the result on success" do
      result = service.with_transaction do
        Shamu::Services::Result.new
      end

      expect(result).to(be_a(Shamu::Services::Result))
    end

    it "returns the result on failure" do
      result = service.with_transaction do
        Shamu::Services::Result.new.tap do |r|
          r.errors.add(:base, "Failure")
        end
      end

      expect(result).to(be_a(Shamu::Services::Result))
      expect(result).not_to(be_valid)
    end

    it "does not modify the database on failures" do
      expect do
        service.with_transaction do
          ActiveRecordSpec::Favorite.create!(name: "Example")
          Shamu::Services::Result.new.tap do |r|
            r.errors.add(:base, "Failure")
          end
        end
      end.not_to(change(ActiveRecordSpec::Favorite, :count))
    end

    it "raises nested exceptions" do
      expect do
        service.with_transaction do
          raise NotImplementedError
        end
      end.to(raise_error(NotImplementedError))
    end
  end
end