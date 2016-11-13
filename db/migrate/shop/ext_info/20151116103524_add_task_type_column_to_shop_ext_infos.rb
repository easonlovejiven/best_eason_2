class AddTaskTypeColumnToShopExtInfos < ActiveRecord::Migration
  def change
    add_column :shop_ext_infos, :task_type, :string
    rename_column :shop_ext_infos, :event_id, :task_id
  end
end
