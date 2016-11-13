class CreateWelfarePapers < ActiveRecord::Migration
  def change
    create_table :welfare_papers do |t|
      t.string :key
      t.string :pic
      t.integer :creator_id
      t.integer :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_column :manage_roles, :welfare_paper, :integer, default: 0
    add_column :manage_roles, :welfare_letter, :integer, default: 0
  end
end
