class AddNotificationSendToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :notification_send, :integer, default: 0
  end
end
