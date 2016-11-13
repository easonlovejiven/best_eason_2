class AddActiveToShopAddresses < ActiveRecord::Migration
  def change
    add_column :shop_addresses, :active, :boolean, default: true
  end
end
