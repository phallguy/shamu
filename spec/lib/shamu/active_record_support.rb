require "active_record"
require "shamu/entities/active_record"
require "shamu/entities/active_record_soft_destroy"

module ActiveRecordSpec
  class Favorite < ::ActiveRecord::Base
    self.table_name = "favorites"
    extend ::Shamu::Entities::ActiveRecord
    include ::Shamu::Entities::ActiveRecordSoftDestroy

    scope :by_name, ->( name ) { where( name: name ) }
    scope :by_label, ->( label ) { where( label: label ) }
  end

  class FavoriteMigration < ::ActiveRecord::Migration
    def self.up
      create_table :favorites do |t|
        t.string :name
        t.string :label

        t.datetime :destroyed_at
      end
    end

    def self.down
      drop_table :favorites
    end
  end

  class FavoriteScope < Shamu::Entities::ListScope
    attribute :name
  end

  class FavoriteEntity < Shamu::Entities::Entity
    model :record
    attribute :name, on: :record
  end
end
