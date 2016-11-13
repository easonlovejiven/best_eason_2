class CreateShopVideos < ActiveRecord::Migration
  def change
    create_table :shop_videos do |t|
      t.integer :videoable_id
      t.string :videoable_type
      t.string :key
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
