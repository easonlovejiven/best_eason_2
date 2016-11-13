class AddDefaultToCoreUsers < ActiveRecord::Migration
  def change
    change_column :core_users, :identity, :integer, default: 0
  end
end
