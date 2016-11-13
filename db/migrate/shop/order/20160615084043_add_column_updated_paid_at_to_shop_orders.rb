class AddColumnUpdatedPaidAtToShopOrders < ActiveRecord::Migration
  def change
    add_column :shop_orders, :updated_paid_at, :datetime
  end
end
