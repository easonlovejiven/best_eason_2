class AddColumnStarListToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :star_list, :string
  end
end
