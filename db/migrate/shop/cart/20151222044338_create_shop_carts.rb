class CreateShopCarts < ActiveRecord::Migration
  def change
    create_table :shop_carts do |t|
      t.integer :uid

      t.timestamps null: false
    end
  end
end
