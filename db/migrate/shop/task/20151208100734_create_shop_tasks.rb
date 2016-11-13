class CreateShopTasks < ActiveRecord::Migration
  def change
    create_table :shop_tasks do |t|
      t.string :title
      t.string :description
      t.boolean :active, default: true
      t.integer :user_id
      t.integer :creator_id
      t.integer :shop_id
      t.string :shop_type

      t.timestamps null: false
    end
  end
end
