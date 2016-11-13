class AddColumnIsTopToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :is_top, :boolean, default: false
    add_index :shop_tasks, [:active, :is_top, :participants, :position], name: 'by_is_top_and_position'
    add_index :shop_tasks, [:active, :category, :shop_type], name: 'by_category_and_shop_type'
  end
end
