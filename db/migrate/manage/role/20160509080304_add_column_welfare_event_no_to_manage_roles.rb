class AddColumnWelfareEventNoToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :welfare_event, :integer, default: 0
    add_column :manage_roles, :welfare_product, :integer, default: 0
    add_column :manage_roles, :core_expen, :integer, default: 0
  end
end
