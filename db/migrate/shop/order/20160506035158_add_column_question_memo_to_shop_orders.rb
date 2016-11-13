class AddColumnQuestionMemoToShopOrders < ActiveRecord::Migration
  def change
    add_column :shop_orders, :question_memo, :text
  end
end
