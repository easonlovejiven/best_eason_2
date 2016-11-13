class CreateShopFundingOrders < ActiveRecord::Migration
  def change
    create_table :shop_funding_orders do |t|
      t.string :order_no
      t.references :shop_funding
      t.integer :user_id
      t.integer :status, default: 1
      t.integer :pay_type, default: 1
      t.integer :quantity, default: 1
      t.decimal :payment, default: 0.00 , :precision => 8, :scale => 2
      t.datetime :paid_at
      t.datetime :pay_at
      t.datetime :canceled_at
      t.datetime :checked_at
      t.integer :address_id
      t.integer :owner_id
      t.integer :shop_ticket_type_id
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
