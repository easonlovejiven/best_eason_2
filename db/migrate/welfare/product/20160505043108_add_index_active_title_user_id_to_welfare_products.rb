class AddIndexActiveTitleUserIdToWelfareProducts < ActiveRecord::Migration
  def change
    add_index  :welfare_products, [:active, :title, :user_id, :mobile, :star_list],  unique: true, name: "welfare_product_active"
    add_index  :welfare_events, [:active, :title, :user_id, :mobile, :star_list],  unique: true, name: "welfare_event_active"
  end
end
