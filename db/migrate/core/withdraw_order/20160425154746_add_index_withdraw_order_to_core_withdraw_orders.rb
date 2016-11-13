class AddIndexWithdrawOrderToCoreWithdrawOrders < ActiveRecord::Migration
  def change
    add_index  :core_withdraw_orders, [:task_id, :task_type, :requested_by, :requested_at, :status],  unique: true, name: "task_and_request"
  end
end
