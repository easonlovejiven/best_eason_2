class AddStarListToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :star_list, :string
  end
end
