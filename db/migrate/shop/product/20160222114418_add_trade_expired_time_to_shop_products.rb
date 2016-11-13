class AddTradeExpiredTimeToShopProducts < ActiveRecord::Migration
  def change
    add_column :shop_products, :trade_expired_time, :integer, default: 20
  end
end
