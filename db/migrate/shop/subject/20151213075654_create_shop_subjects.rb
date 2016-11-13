class CreateShopSubjects < ActiveRecord::Migration
  def change
    create_table :shop_subjects do |t|
      t.string :guide
      t.text :description
      t.integer :user_id
      t.integer :creator_id
      t.string :star_list
      t.boolean :active, default: true
      t.string :title

      t.timestamps null: false
    end
  end
end
