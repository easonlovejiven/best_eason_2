class AddColumnCreatedTimeToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :created_time, :datetime
  end
end
