class CreateShopTaskStars < ActiveRecord::Migration
  def change
    create_table :shop_task_stars do |t|
      t.integer :shop_task_id
      t.integer :core_star_id
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
