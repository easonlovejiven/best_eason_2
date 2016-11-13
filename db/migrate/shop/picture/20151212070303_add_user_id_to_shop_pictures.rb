class AddUserIdToShopPictures < ActiveRecord::Migration
  def change
    add_column :shop_pictures, :user_id, :integer
  end
end
