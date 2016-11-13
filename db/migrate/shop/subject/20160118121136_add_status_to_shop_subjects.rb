class AddStatusToShopSubjects < ActiveRecord::Migration
  def change
    add_column :shop_subjects, :status, :integer, default: 0
    add_column :shop_subjects, :start_at, :datetime
    add_column :shop_subjects, :live_url, :string #视频直播地址
    add_column :shop_subjects, :storage_url, :string #视频存储地址
    add_column :shop_subjects, :shop_category, :string, default: 'shop_subjects'
    add_column :shop_subjects, :category, :string
  end
end
