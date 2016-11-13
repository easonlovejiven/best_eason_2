class AddColumnUpdatedPaidAtToShopFundingOrders < ActiveRecord::Migration
  def change
    add_column :shop_funding_orders, :updated_paid_at, :datetime
  end
end
