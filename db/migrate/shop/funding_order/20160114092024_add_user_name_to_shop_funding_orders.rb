class AddUserNameToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :user_name, :string
    add_column :shop_funding_orders, :phone, :string
  end
end
