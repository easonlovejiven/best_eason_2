class AddColumnRoleToCoreUsers < ActiveRecord::Migration
  def change
  	add_column :core_users, :role, :string
  end
end
