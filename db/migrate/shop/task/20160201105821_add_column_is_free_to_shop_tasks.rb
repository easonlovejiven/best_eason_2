class AddColumnIsFreeToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :free, :boolean, default: false
  end
end
