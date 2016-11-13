class ChangeColumnPaidAtToShopOrders < ActiveRecord::Migration
  def change
    rename_column :shop_orders, :pay_at, :paid_at
  end
end
