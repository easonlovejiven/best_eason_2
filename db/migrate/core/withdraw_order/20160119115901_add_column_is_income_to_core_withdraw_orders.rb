class AddColumnIsIncomeToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    add_column :core_withdraw_orders, :is_income, :boolean, default: false
  end
end
