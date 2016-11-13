class AddColumnFreeToShopFundings < ActiveRecord::Migration
  def change
    change_column :shop_fundings, :free, :boolean, default: false
  end
end
