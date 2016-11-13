class AddShopFreightTemplateToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_freight_template, :integer, default: 0
  end
end
