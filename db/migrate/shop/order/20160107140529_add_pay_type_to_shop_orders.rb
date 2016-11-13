class AddPayTypeToShopOrders < ActiveRecord::Migration
  def change
    add_column :shop_orders, :pay_type, :integer
  end
end
