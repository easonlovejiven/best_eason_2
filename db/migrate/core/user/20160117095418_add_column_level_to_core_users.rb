class AddColumnLevelToCoreUsers < ActiveRecord::Migration
  def change
    change_column :core_users, :level, :integer, default: 0
  end
end
