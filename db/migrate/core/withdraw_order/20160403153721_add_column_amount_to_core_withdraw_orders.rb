class AddColumnAmountToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    change_column :core_withdraw_orders, :amount, :decimal, default: 0.00 , :precision => 8, :scale => 2
  end
end
