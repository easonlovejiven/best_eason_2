class AddCategoryToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :shop_category, :string
  end
end
