class AddColumnSplitMemoToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :split_memo, :string
  end
end
