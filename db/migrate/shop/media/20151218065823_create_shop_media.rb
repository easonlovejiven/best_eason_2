class CreateShopMedia < ActiveRecord::Migration
  def change
    create_table :shop_media do |t|
      t.string :title
      t.datetime :start_at
      t.datetime :end_at
      t.string :star_list
      t.string :url
      t.string :pic
      t.integer :user_id
      t.boolean :active, default: true, null: false
      t.integer :lock_version, default: 0, null: false
      t.timestamps null: false
    end
    add_column :qa_posters, :star_list, :string
  end
end
