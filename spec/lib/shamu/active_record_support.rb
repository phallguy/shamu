require "active_record"
require "shamu/entities/active_record"

module ActiveRecordSpec
  class Favorite < ::ActiveRecord::Base
    self.table_name = "favorites"
    extend Shamu::Entities::ActiveRecord

    scope :by_name, ->( name ) { where( name: name ) }
  end

  class FavoriteMigration < ::ActiveRecord::Migration
    def self.up
      create_table :favorites do |t|
        t.string :name
      end
    end

    def self.down
      drop_table :favorites
    end
  end

  class FavoriteScope < Shamu::Entities::ListScope
    attribute :name
  end
end