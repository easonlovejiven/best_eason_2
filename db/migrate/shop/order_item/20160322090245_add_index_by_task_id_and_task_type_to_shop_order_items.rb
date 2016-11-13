class AddIndexByTaskIdAndTaskTypeToShopOrderItems < ActiveRecord::Migration
  def change
    add_index :shop_order_items, ["owhat_product_id", "owhat_product_type"],     :name => "by_owhat_product_id_and_owhat_product_type"
    add_index :shop_funding_orders, ["shop_funding_id"],     :name => "by_shop_funding_id"
  end
end
