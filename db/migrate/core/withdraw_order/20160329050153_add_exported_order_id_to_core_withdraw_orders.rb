class AddExportedOrderIdToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    add_column :core_withdraw_orders, :core_exported_order_id, :integer
  end
end
