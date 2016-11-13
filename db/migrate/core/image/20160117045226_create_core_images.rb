class CreateCoreImages < ActiveRecord::Migration
  def change
    create_table :core_images do |t|
      t.string :pic
      t.string :key
      t.integer :creator_id
      t.integer :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0

      t.timestamps null: false
    end
    add_column :manage_roles, :core_image, :integer, default: 0
    add_column :core_users, :image_id, :integer
  end
end
