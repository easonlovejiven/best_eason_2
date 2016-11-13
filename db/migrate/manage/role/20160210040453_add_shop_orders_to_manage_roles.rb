class AddShopOrdersToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :core_withdraw_order, :integer, default: 0
    add_column :manage_roles, :shop_funding_order, :integer, default: 0
    add_column :manage_roles, :core_exported_order, :integer, default: 0
  end
end
