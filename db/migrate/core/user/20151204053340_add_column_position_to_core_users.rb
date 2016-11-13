class AddColumnPositionToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :position, :integer, default: 0
    add_column :core_users, :verified_at, :datetime
    add_column :core_users, :verified, :boolean, default: false
    add_column :core_users, :creator_id, :integer
    add_column :core_users, :updater_id, :integer
  end
  # add_index :core_users, [:active, :identity], name: "by_active_and_identity"
end
