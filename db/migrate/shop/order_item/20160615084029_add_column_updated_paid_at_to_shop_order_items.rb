class AddColumnUpdatedPaidAtToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :updated_paid_at, :datetime
  end
end
