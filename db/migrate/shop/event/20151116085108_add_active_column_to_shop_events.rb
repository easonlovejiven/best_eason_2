class AddActiveColumnToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :active, :boolean
  end
end
