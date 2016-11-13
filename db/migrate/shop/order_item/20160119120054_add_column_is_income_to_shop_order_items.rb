class AddColumnIsIncomeToShopOrderItems < ActiveRecord::Migration
  def change
    add_column :shop_order_items, :is_income, :boolean, default: true #收入对发布者来说
  end
end
