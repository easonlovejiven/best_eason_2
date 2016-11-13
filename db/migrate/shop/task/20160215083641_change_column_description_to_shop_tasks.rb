class ChangeColumnDescriptionToShopTasks < ActiveRecord::Migration
  def change
    change_column :shop_tasks, :description, :text
  end
end
