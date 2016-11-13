class CreateNotificationSends < ActiveRecord::Migration
  def change
    create_table :notification_sends do |t|
      t.text :content
      t.integer :sendor_id
      t.text :extro
      t.string :object_name, default: 'RC:TxtMsg'
      t.string :push_data
      t.string :push_content
      t.string :os, default: 'iOS'
      t.integer :receivor_id
      t.integer :creator_id
      t.integer :updater_id
      t.boolean :status, default: false
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
