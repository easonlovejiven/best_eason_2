class AddGudieToShopProducts < ActiveRecord::Migration
  def change
    add_column :shop_products, :guide, :string
  end
end
