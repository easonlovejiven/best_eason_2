class AddIndexUserIdToExpens < ActiveRecord::Migration
  def change
    add_index :core_expens, :user_id, name: 'by_user_id'
  end
end
