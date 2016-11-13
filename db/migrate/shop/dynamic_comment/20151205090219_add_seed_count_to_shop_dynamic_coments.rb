class AddSeedCountToShopDynamicComents < ActiveRecord::Migration
  def change
    add_column :shop_dynamic_comments, :seed_count, :integer, default: 0 #子评论个数
  end
end
