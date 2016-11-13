class CreateShopEvents < ActiveRecord::Migration
  def change
    create_table :shop_events do |t|
      t.integer :user_id
      t.string :title
      t.integer :area_id
      t.string :address
      t.integer :ticket_limit
      t.integer :ticket_total
      t.string :mobile
      t.text :description
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :seckill_start_at
      t.float :fee
      t.float :original_fee
      t.boolean :is_hot
      t.float :latitude
      t.float :longitude
      t.integer :comments_count, default: 0
      t.integer :tickets_count, default: 0
      t.boolean :free, default: false
      t.boolean :sync_weibo
      t.boolean :sync_qq
      t.string :reg_fields
      t.string :ext_info
      t.string :video_url
      t.string :update_reason
      t.string :cover1
      t.string :cover2
      t.string :cover3
      t.string :cover1_fingerprint
      t.string :cover2_fingerprint
      t.string :cover3_fingerprint
      t.integer :priority, default: 100
      t.datetime :deleted_at
      t.datetime :sale_start_at
      t.datetime :sale_end_at
      t.datetime :select_at
      t.string :select_place
      t.boolean :hidden, default: false
      t.string :success_redirect_url
      t.boolean :send_coupon_code, default: false
      t.integer :flag_id
      t.string :cached_tag_list
      t.string :product_type, default: 'event' #现在不需要了 已经将表分开
      t.decimal :funding_target #影院类的 商品活动不需要
      t.string :live_room_id
      t.boolean :auto_creating_live_room, default: false
      t.boolean :send_sms, default: true
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.integer :trade_expired_time, limit: 8
      t.boolean :require_address, default: true
      t.string :cached_star_list
      t.integer :orbit_id

      t.timestamps null: false
    end
  end
end
