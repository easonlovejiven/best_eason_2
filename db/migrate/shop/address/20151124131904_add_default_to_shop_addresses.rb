class AddDefaultToShopAddresses < ActiveRecord::Migration
  def change
    rename_column :shop_addresses, :dafault, :is_default
  end
end
