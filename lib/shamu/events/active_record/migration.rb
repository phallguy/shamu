module Shamu
  module Events
    module ActiveRecord

      # Prepare the database for storing event messages.
      class Migration < ::ActiveRecord::Migration[5.0]

        self.verbose = false

        # rubocop:disable Metrics/MethodLength

        def up
          return if data_source_exists? Message.table_name

          # TODO: Need to provide a means for using 64-bit primary keys in
          # databases that support it. Otherwise limited to 4B events.
          create_table Message.table_name do |t|
            t.integer :channel_id, null: false
            t.string  :message, null: false

            t.index :id
            t.index :channel_id
          end

          create_table Channel.table_name do |t|
            t.string :name, null: false, unique: true

            t.index :name
          end

          create_table Runner.table_name, id: false do |t|
            t.timestamp :last_processed_at
            t.integer   :last_processed_id
            t.string    :id, null: false

            t.index :id, unique: true
          end
        end

        def down
          drop_table Message.table_name if data_source_exists? Message.table_name
          drop_table Channel.table_name if data_source_exists? Channel.table_name
          drop_table Runner.table_name  if data_source_exists? Runner.table_name
        end

      end
    end
  end
end
