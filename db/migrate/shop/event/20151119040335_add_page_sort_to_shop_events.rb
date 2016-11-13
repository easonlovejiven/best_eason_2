class AddPageSortToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :page_sort, :integer
    add_column :shop_products, :page_sort, :integer
    add_column :shop_fundings, :page_sort, :integer
  end
end
