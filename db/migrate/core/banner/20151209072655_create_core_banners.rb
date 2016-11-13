class CreateCoreBanners < ActiveRecord::Migration
  def change
    create_table :core_banners do |t|
      t.string :title
      t.string :link
      t.string :pic
      t.string :genre
      t.string :position
      t.text :description
      t.datetime :start_at
      t.datetime :end_at
      t.integer  :creator_id
      t.integer  :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_column :manage_roles, :core_banner, :integer, default: 0
    add_index :core_banners, [:active, :published, :start_at, :end_at], name: 'by_start_at_and_end_at_banners'
  end
end
