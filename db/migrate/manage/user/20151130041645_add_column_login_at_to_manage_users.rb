class AddColumnLoginAtToManageUsers < ActiveRecord::Migration
  def change
  	add_column :manage_users, :login_at, :datetime
  end
end
