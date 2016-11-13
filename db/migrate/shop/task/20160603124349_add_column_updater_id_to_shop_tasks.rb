class AddColumnUpdaterIdToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :updater_id, :integer
  end
end
