class AddColumnFreeToShopProducts < ActiveRecord::Migration
  def change
    change_column :shop_products, :free, :boolean, default: false
  end
end
