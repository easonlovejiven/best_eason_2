class AddActiveToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :active, :boolean, default: true
  end
end
