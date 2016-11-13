class AddColumnSequenceToCoreBanners < ActiveRecord::Migration
  def change
    add_column :core_banners, :sequence, :integer, null: false, default: 9999
  end
end
