class ChangeColumnTitleToShopSubjects < ActiveRecord::Migration
  def change
    change_column :shop_subjects, :title, :text
  end
end
