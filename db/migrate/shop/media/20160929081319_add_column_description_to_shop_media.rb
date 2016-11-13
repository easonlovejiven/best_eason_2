class AddColumnDescriptionToShopMedia < ActiveRecord::Migration
  def change
    add_column :shop_media, :description, :text
    add_column :shop_media, :kind, :string, default: 'url'
  end
end
