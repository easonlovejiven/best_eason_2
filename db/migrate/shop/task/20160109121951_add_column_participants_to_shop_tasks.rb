class AddColumnParticipantsToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :participants, :integer, default: 0
    add_column :shop_tasks, :position, :integer, default: 0
  end
end
