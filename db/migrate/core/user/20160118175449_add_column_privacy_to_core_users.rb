class AddColumnPrivacyToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :privacy, :boolean, default: true
  end
end
