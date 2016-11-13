class AddColumnCoreHotRecordsToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :core_hot_record, :integer, default: 0
  end
end
