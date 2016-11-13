class AddGudieToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :guide, :string
  end
end
