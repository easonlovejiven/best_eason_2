class AddColumnIsAutoShareToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :is_auto_share, :boolean, null: true
  end
end
