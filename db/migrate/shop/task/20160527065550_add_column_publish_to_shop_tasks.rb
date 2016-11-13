class AddColumnPublishToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :published, :boolean, null: false, default: false
  end
end
