class AddIndexPublishedToCoreTasks < ActiveRecord::Migration
  def change
    add_index :shop_tasks, [:active, :published, :expired_at, :user_id], name: 'by_active_and_published'
    add_index :shop_tasks, [:active, :published, :is_top], name: 'by_active_and_is_top'
    add_index :shop_tasks, [:active, :published, :category], name: 'by_active_and_category'
    add_index :shop_tasks, [:active, :participants, :position], name: 'by_active_and_participants'
    add_index :shop_tasks, [:active, :shop_type, :updated_at], name: 'by_active_and_updated_at'
  end
end
