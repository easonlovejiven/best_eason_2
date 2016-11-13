class AddColumnStarNamesToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :star_names, :string
  end
end
