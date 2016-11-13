class CreateShopComments < ActiveRecord::Migration
  def change
    create_table :shop_comments do |t|
      t.integer :parent_id
      t.integer :task_id
      t.string :task_type
      t.text :content
      t.integer :user_id
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
