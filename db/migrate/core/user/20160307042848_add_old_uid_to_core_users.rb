class AddOldUidToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :old_uid, :integer
  end
end
