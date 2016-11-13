class AddTradeExpiredTimeToShopEvents < ActiveRecord::Migration
  def change
    change_column :shop_events, :trade_expired_time, :integer, default: 20
  end
end
