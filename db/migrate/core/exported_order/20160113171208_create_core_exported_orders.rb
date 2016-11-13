class CreateCoreExportedOrders < ActiveRecord::Migration
  def change
    create_table :core_exported_orders do |t|
      t.integer :user_id
      t.boolean :active, default: true
      t.integer :task_id
      t.string :task_type
      t.string :file_name

      t.timestamps null: false
    end
  end
end
