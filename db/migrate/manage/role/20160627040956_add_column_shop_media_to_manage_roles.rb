class AddColumnShopMediaToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_media, :integer, default: 0
  end
end
