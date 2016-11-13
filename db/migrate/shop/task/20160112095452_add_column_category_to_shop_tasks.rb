class AddColumnCategoryToShopTasks < ActiveRecord::Migration
  def change
    rename_column :shop_tasks, :categroy, :category
  end
end
