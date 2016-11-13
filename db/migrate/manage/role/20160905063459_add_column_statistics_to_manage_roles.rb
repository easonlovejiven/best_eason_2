class AddColumnStatisticsToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :statistic, :integer, default: 0
  end
end
