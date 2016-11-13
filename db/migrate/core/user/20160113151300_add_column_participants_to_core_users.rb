class AddColumnParticipantsToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :participants, :integer, default: 0
    add_index :core_users, [:active, :participants, :created_at], name: "index_core_users_on_participants_and_active"
  end
end
