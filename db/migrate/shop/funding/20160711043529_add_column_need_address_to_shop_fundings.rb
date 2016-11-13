class AddColumnNeedAddressToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :need_address, :boolean, default: false
  end
end
