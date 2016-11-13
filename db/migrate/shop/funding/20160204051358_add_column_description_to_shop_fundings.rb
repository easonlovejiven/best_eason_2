class AddColumnDescriptionToShopFundings < ActiveRecord::Migration
  def change
    change_column :shop_fundings, :description, :text
  end
end
