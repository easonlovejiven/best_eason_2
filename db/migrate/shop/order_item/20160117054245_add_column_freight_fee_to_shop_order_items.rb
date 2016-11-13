class AddColumnFreightFeeToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :freight_fee, :decimal, default: 0.00 , :precision => 8, :scale => 2
  end
end
