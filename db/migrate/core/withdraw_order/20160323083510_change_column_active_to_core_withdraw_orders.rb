class ChangeColumnActiveToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    change_column :core_withdraw_orders, :active, :boolean, default: true
  end
end
