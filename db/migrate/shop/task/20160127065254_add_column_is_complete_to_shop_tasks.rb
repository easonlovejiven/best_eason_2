class AddColumnIsCompleteToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :is_complete, :boolean, default: true
    add_column :shop_tasks, :completed_at, :datetime
  end
end
