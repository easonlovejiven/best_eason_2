class AlterColumnByNotificationSends < ActiveRecord::Migration
  def up
  	remove_column :notification_sends, :os
    add_column :notification_sends, :os, :string, default: 'all'
  end

  def down
  	remove_column :notification_sends, :os
    add_column :notification_sends, :os, :string, default: 'iOS'
  end
end
