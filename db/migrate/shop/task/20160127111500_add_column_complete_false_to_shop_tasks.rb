class AddColumnCompleteFalseToShopTasks < ActiveRecord::Migration
  def change
    change_column :shop_tasks, :is_complete, :boolean, default: false
  end
end
