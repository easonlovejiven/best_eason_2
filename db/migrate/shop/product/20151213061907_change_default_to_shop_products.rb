class ChangeDefaultToShopProducts < ActiveRecord::Migration
  def change
    change_column :shop_products, :is_need_express, :boolean, default: true
    change_column :shop_products, :free, :boolean, default: true
  end
end
