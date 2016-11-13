class AddCategoryToShopProducts < ActiveRecord::Migration
  def change
    add_column :shop_products, :shop_category, :string
  end
end
