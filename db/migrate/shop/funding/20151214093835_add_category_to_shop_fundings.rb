class AddCategoryToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :shop_category, :string
  end
end
