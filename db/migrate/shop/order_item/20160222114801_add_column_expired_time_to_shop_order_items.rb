class AddColumnExpiredTimeToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :expired_at, :datetime
  end
end
