class CreateShopTopics < ActiveRecord::Migration
  def change
    create_table :shop_topics do |t|
      t.string :title
      t.boolean :active, default: true
      t.text :description
      t.string :cover1 #封面1
      t.integer :user_id
      t.boolean :is_share #是否作为分享任务

      t.timestamps null: false
    end
  end
end
