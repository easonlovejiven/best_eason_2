class AddColumnIsSharedToShopSubjects < ActiveRecord::Migration
  def change
    add_column :shop_subjects, :is_share, :boolean, default: true
  end
end
