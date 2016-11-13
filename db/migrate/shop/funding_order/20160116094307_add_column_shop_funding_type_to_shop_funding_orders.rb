class AddColumnShopFundingTypeToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :shop_funding_type, :string, default: 'Shop::Funding'
  end
end
