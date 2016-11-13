class AddColumnCreatorIdAndUpdaterIdToShopMedias < ActiveRecord::Migration
  def change
    add_column :shop_media, :creator_id, :integer
    add_column :shop_media, :updater_id, :integer
  end
end
