class AddColumnSplitMemoToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :split_memo, :string
  end
end
