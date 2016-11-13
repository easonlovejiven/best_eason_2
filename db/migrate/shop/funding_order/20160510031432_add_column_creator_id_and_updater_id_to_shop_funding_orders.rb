class AddColumnCreatorIdAndUpdaterIdToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :creator_id, :integer
    add_column :shop_funding_orders, :updater_id, :integer
  end
end
