class AddPlatformToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :platform, :string
  end
end
