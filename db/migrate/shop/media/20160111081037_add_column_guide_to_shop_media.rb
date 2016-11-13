class AddColumnGuideToShopMedia < ActiveRecord::Migration
  def change
    add_column :shop_media, :guide, :string
    add_column :shop_media, :is_share, :boolean, default: false
  end
end
