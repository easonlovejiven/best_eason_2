class AddShopEventToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_event, :integer, default: 0
  end
end
