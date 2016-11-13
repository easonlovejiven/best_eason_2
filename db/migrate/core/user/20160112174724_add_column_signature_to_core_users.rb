class AddColumnSignatureToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :signature, :text
  end
end
