class AddKeyToShopSubjects < ActiveRecord::Migration
  def change
    add_column :shop_subjects, :key, :string
    add_column :shop_subjects, :cover1, :string
  end
end
