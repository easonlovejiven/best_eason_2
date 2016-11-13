class AddColumnPic2ToCoreBanners < ActiveRecord::Migration
  def change
    add_column :core_banners, :pic2, :string
  end
end
