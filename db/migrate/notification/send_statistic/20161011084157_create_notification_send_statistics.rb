class CreateNotificationSendStatistics < ActiveRecord::Migration
  def change
    create_table :notification_send_statistics do |t|
      t.integer :send_id
      t.integer :uid
      t.string :platform

      t.timestamps null: false
    end
    add_index "notification_send_statistics", ["send_id", "platform"], name: "by_send_id_and_platform", using: :btree
  end
end
