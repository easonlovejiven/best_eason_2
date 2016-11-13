class RenameOrderItemIdToResourceIdToExpens < ActiveRecord::Migration
  def change
    rename_column :shop_ext_info_values, :order_item_id, :resource_id
  end
end
