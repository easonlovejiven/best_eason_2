class AddIndexVerifiedToCoreUsers < ActiveRecord::Migration
  def change
    add_index :core_users, [:verified, :active], name: 'by_verified_and_active'
  end
end
