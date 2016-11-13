class CreateShopDynamicComments < ActiveRecord::Migration
  def change
    create_table :shop_dynamic_comments do |t|
      t.string :content
      t.integer :user_id
      t.integer :parent_id
      t.integer :dynamic_id
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
