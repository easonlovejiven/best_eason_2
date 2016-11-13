class AddColumnParentIdToShopDynamicComments < ActiveRecord::Migration
  def change
    change_column :shop_dynamic_comments, :parent_id, :integer, default: 0
  end
end
