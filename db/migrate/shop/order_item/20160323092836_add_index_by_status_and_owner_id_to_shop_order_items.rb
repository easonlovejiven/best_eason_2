class AddIndexByStatusAndOwnerIdToShopOrderItems < ActiveRecord::Migration
  def change
    add_index :shop_funding_orders, ["status", "owner_id"],     :name => "by_funding_status_and_owner_id"
    add_index :shop_order_items, ["status", "owner_id"],     :name => "by_shop_status_and_owner_id"
    add_index :core_withdraw_orders, ["status", "requested_by"],     :name => "by_withdraw_status_and_requested_by"
  end
end
