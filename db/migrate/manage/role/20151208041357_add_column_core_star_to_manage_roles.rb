class AddColumnCoreStarToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :core_star, :integer, default: 0
  end
end
