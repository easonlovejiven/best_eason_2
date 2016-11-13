class AddColumnUserTypeToCoreExportedOrders < ActiveRecord::Migration
  def change
    add_column :core_exported_orders, :user_type, :string
  end
end
