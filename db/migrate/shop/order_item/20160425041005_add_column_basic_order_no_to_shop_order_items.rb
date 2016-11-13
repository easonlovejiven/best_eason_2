class AddColumnBasicOrderNoToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :basic_order_no, :string 
  end
end
