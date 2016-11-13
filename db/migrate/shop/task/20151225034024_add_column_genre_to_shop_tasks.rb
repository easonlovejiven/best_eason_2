class AddColumnGenreToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :pic, :string
    add_column :shop_tasks, :categroy, :string
  end
end
