class AddActiveToShopOrders < ActiveRecord::Migration
  def change
    add_column :shop_orders, :active, :boolean, default: true
    add_column :shop_orders, :freight_fee, :decimal, default: 0.00 , precision: 8, scale: 2
  end
end
