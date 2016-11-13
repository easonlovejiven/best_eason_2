class AddIdentityToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :identity, :integer
  end
end
