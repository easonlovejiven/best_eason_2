class CreateShopProducts < ActiveRecord::Migration
  def change
    create_table :shop_products do |t|
      t.string :title
      t.boolean :active, default: true
      t.integer :user_id
      t.string :description
      t.string :cover1
      t.string :cover2
      t.string :cover3
      t.string :video_url
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :sale_start_at
      t.datetime :sale_end_at
      t.string :address
      t.string :mobile
      t.boolean :free

      t.timestamps null: false
    end
  end
end
