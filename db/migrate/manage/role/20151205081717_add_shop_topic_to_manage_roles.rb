class AddShopTopicToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_topic, :integer, default: 0
  end
end
