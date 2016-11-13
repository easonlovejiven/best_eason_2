class AddGudieToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :guide, :string
  end
end
