class AddPlatformToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :platform, :string
  end
end
