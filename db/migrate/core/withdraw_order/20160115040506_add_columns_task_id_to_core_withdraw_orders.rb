class AddColumnsTaskIdToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    add_column :core_withdraw_orders, :task_id, :integer
    add_column :core_withdraw_orders, :task_type, :string
    change_column :core_withdraw_orders, :status, :integer, default: 1
  end
end
