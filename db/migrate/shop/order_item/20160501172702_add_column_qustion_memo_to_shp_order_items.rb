class AddColumnQustionMemoToShpOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :question_memo, :text
    add_column :shop_funding_orders, :question_memo, :text
  end
end
