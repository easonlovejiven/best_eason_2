class AddUpdaterIdToShopProducts < ActiveRecord::Migration
  def change
    add_column :shop_products, :updater_id, :integer
    add_column :shop_products, :is_rush, :boolean, default: false #是否抢购商品
  end
end
