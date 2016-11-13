class AddColumnAddressShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :address, :string
  end
end
