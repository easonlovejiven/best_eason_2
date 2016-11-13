class AddCreatorIdToShopProducts < ActiveRecord::Migration
  def change
    add_column :shop_products, :creator_id, :integer
    add_column :shop_products, :is_need_express, :boolean
    add_column :shop_products, :descripe_cover, :string
    add_column :shop_products, :descripe2, :string
    add_column :shop_products, :key1, :string
    add_column :shop_products, :key2, :string
    add_column :shop_products, :key3, :string
    add_column :shop_products, :descripe_key, :string
    add_column :shop_products, :star_list, :string
    add_column :shop_products, :is_share, :boolean
    add_column :shop_products, :freight_template_id, :integer
    change_column :shop_products, :description, :text
    change_column :shop_products, :descripe2, :text
  end
end
