class AddShopTopicDynamicToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_topic_dynamic, :integer, default: 0
  end
end
