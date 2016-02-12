require "spec_helper"
require "shamu/services"
require "shamu/services/active_record"

describe Shamu::Services::ActiveRecord do
  let( :klass ) do
    Class.new( Shamu::Services::Service ) do
      include Shamu::Services::ActiveRecord
      public :wrap_not_found, :scope_relation
    end
  end
  let( :service ) { scorpion.new klass }

  describe "#wrap_not_found" do
    it "re-raises AR not found as shamu not found" do
      expect do
        service.wrap_not_found do
          raise ActiveRecord::RecordNotFound
        end
      end.to raise_error Shamu::NotFoundError
    end
  end

  describe "#scope_relation" do
    use_active_record

    it "short-circuits if no relation" do
      expect( service.scope_relation( nil, nil ) ).to be_nil
    end

    it "invokes by_list_scope if available" do
      scope    = ActiveRecordSpec::FavoriteScope.new
      relation = ActiveRecordSpec::Favorite.all

      expect( relation ).to receive( :by_list_scope )
      service.scope_relation( relation, scope )
    end

    it "it raises helpful error if relation isn't scopable" do
      scope    = ActiveRecordSpec::FavoriteScope.new
      relation = ActiveRecordSpec::Favorite.all

      expect( relation ).to receive( :respond_to? ).and_return false

      expect do
        service.scope_relation( relation, scope )
      end.to raise_error /by_list_scope/
    end
  end
end