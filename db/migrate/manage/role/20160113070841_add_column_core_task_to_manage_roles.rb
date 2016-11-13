class AddColumnCoreTaskToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_task, :integer, default: 0
  end
end
