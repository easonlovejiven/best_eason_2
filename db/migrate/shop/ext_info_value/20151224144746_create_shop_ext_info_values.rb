class CreateShopExtInfoValues < ActiveRecord::Migration
  def change
    create_table :shop_ext_info_values do |t|
      t.integer :ext_info_id
      t.integer :order_item_id
      t.string :value
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
