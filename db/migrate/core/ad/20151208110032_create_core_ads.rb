class CreateCoreAds < ActiveRecord::Migration
  def change
    create_table :core_ads do |t|
      t.string :title
      t.string :link
      t.string :pic
      t.string :genre
      t.integer :duration, null: false, default: 3
      t.datetime :start_at
      t.datetime :end_at
      t.integer  :creator_id
      t.integer  :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_column :manage_roles, :core_ad, :integer, default: 0
    add_index :core_ads, [:active, :published, :start_at, :end_at], name: 'by_start_at_and_end_at'
  end
end
