class CreateCoreStars < ActiveRecord::Migration
  def change
    create_table :core_stars do |t|
      t.string :name
      t.string :pic
      t.text :description
      t.string :company
      t.text :works
      t.text :acting
      t.text :related_ids
      t.integer :creator_id
      t.integer :updater_id
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_index :core_stars, [:active, :name], name: "by_active_name"
  end
end
 