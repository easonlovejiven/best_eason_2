class AddColumnIsIncomeToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :is_income, :boolean, default: true
  end
end
