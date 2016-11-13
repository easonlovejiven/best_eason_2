class AddColumnParticipantsToCoreStars < ActiveRecord::Migration
  def change
    add_column :core_stars, :participants, :integer, default: 0
    add_index :core_stars, [:active, :published, :participants, :created_at], name: "index_core_stars_on_participants_and_active"
  end
end
