class AddCreatorIdToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :updater_id, :integer
    add_column :shop_events, :is_rush, :boolean, default: false #是否抢购商品
  end
end
