class AddColumnCreatorIdAndUpdaterIdToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :creator_id, :integer
    add_column :shop_order_items, :updater_id, :integer
  end
end
