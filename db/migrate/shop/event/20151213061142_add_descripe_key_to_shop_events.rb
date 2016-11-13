class AddDescripeKeyToShopEvents < ActiveRecord::Migration
  def change
    rename_column :shop_events, :shop_freight_template_id, :freight_template_id
    rename_column :shop_events, :orbit_id, :creator_id
    rename_column :shop_events, :auto_creating_live_room, :is_need_express
    rename_column :shop_events, :require_address, :is_share
    rename_column :shop_events, :success_redirect_url, :descripe_cover
    rename_column :shop_events, :select_place, :descripe2
    rename_column :shop_events, :cover1_fingerprint, :key1
    rename_column :shop_events, :cover2_fingerprint, :key2
    rename_column :shop_events, :cover3_fingerprint, :key3
    rename_column :shop_events, :update_reason, :descripe_key
    rename_column :shop_events, :reg_fields, :star_list

    change_column :shop_events, :descripe2, :text
    change_column :shop_events, :is_need_express, :boolean, default: true
    change_column :shop_events, :is_share, :boolean, default: true
    change_column :shop_events, :active, :boolean, default: true
    change_column :shop_events, :free, :boolean, default: true
  end
end
