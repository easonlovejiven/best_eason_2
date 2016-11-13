class AddColumnExpiredAtToShopTasks < ActiveRecord::Migration
  def change
    add_column :shop_tasks, :expired_at, :datetime
  end
end
