class AddMemoToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :memo, :string
  end
end
