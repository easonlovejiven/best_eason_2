class AddMemoToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :memo, :string
  end
end
