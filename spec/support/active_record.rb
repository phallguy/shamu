module Support
  module ActiveRecord
    def use_active_record
      require "active_record"
      require_relative "../lib/shamu/active_record_support"

      before( :each ) do
        ActiveRecordSpec::FavoriteMigration.verbose = false
        ActiveRecordSpec::FavoriteMigration.up
      end

      after( :each ) do
        ActiveRecordSpec::FavoriteMigration.down
      end
    end
  end
end