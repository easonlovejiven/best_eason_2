class CreateShopTopicDynamics < ActiveRecord::Migration
  def change
    create_table :shop_topic_dynamics do |t|
      t.string :content
      t.integer :user_id
      t.integer :shop_topic_id
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
