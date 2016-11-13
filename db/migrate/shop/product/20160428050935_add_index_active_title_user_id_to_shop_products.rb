class AddIndexActiveTitleUserIdToShopProducts < ActiveRecord::Migration
  def change
    add_index  :shop_products, [:active, :title, :user_id, :mobile, :star_list],  unique: true, name: "product_active"
    add_index  :shop_events, [:active, :title, :user_id, :mobile, :star_list],  unique: true, name: "event_active"
    add_index  :shop_fundings, [:active, :title, :user_id, :mobile, :star_list],  unique: true, name: "funding_active"
  end
end
