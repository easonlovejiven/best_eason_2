class AddColumnFreeToShopEvents < ActiveRecord::Migration
  def change
    change_column :shop_events, :free, :boolean, default: false
  end
end
