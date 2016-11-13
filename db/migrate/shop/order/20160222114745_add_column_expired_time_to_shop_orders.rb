class AddColumnExpiredTimeToShopOrders < ActiveRecord::Migration
  def change
    add_column :shop_orders, :expired_at, :datetime
  end
end
