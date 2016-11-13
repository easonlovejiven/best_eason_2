class CreateShopOrderItems < ActiveRecord::Migration
  def change
    create_table :shop_order_items do |t|
      t.string :order_no
      t.references :owhat_product, polymorphic: true
      t.integer :user_id
      t.string  :code
      t.integer :status, default: 1
      t.integer :pay_type, default: 1
      t.integer :quantity, default: 1
      t.decimal :payment, default: 0.00 , :precision => 8, :scale => 2
      t.datetime :paid_at
      t.datetime :canceled_at
      t.string :qr_code, limit: 255 #二维码
      t.datetime :checked_at
      t.string   :qr_code_fingerprint, limit: 255
      t.boolean :is_deleted
      t.datetime :paid_sms_sent_at
      t.datetime :qr_code_created_at
      t.string   :qr_path_cache,       limit: 255
      t.datetime :alipay_payment_at
      t.integer :address_id
      t.integer :owner_id
      t.integer :order_id
      t.integer :shop_ticket_type_id
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
