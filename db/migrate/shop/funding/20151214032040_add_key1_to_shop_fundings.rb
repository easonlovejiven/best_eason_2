class AddKey1ToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :key1, :string
    add_column :shop_fundings, :key2, :string
    add_column :shop_fundings, :key3, :string
    add_column :shop_fundings, :descripe_key, :string

    change_column :shop_fundings, :free, :boolean, default: true
    change_column :shop_fundings, :is_share, :boolean, default: true
  end
end
