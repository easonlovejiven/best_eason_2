class AddColumnPaidStartAtToCoreExportedOrders < ActiveRecord::Migration
  def change
    add_column :core_exported_orders, :paid_start_at, :datetime
    add_column :core_exported_orders, :paid_end_at, :datetime
    add_column :core_exported_orders, :exclude_free, :boolean, default: false
    add_column :core_exported_orders, :order_class, :string
  end
end
