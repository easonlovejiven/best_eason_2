class AddUserNameToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :user_name, :string
    add_column :shop_order_items, :phone, :string
    add_column :shop_order_items, :address, :string
  end
end
