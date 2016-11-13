class CreateShopTaskImages < ActiveRecord::Migration
  def change
    create_table :shop_task_images do |t|
      t.string :pic
      t.string :key
      t.string :category
      t.integer :creator_id
      t.integer :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_column :manage_roles, :shop_task_image, :integer, default: 0
  end
end
