class AlterSendColumnAndUpdateSendStatus < ActiveRecord::Migration
  def up
    add_column :notification_sends, :skip_channel, :string
    add_column :notification_sends, :skip_id, :integer
    add_column :notification_sends, :send_status, :integer, default: 1
    add_column :notification_sends, :send_date, :datetime
    add_index :notification_sends, [:send_date, :send_status]
    add_column :notification_sends, :send_type, :integer, default: 1
    add_column :notification_sends, :push_type, :integer, default: 1
    remove_column :notification_sends, :push_data
    remove_column :notification_sends, :object_name
    add_column :notification_sends, :object_name, :string, default: 'custom'
    Notification::Send.update_all(send_status: 2)
  end

  def down
    add_column :notification_sends, :push_data, :string
    remove_column :notification_sends, :object_name
    add_column :notification_sends, :object_name, :string, default: 'RC:TxtMsg'
    remove_column :notification_sends, :skip_channel
    remove_column :notification_sends, :skip_id
    remove_index :notification_sends, [:send_date, :send_status]
    remove_column :notification_sends, :send_status
    remove_column :notification_sends, :send_date
    remove_column :notification_sends, :send_type
    remove_column :notification_sends, :push_type
  end
end
