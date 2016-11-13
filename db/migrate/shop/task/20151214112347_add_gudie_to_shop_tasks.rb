class AddGudieToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :guide, :string
  end
end
