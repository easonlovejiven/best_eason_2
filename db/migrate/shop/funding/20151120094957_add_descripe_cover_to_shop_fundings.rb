class AddDescripeCoverToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :descripe_cover, :string
    add_column :shop_fundings, :descripe2, :string
  end
end
