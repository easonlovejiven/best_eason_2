class CreateShopOrders < ActiveRecord::Migration
  def change
    create_table :shop_orders do |t|
      t.string :order_no
      t.decimal :total_fee, default: 0.00 , :precision => 8, :scale => 2
      t.integer :status, default: 1
      t.string :platform
      t.integer :address_id
      t.datetime :pay_at
      t.integer :user_id
      t.boolean :is_deleted

      t.timestamps null: false
    end
  end
end
