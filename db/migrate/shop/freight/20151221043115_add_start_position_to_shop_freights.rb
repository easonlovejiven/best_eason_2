class AddStartPositionToShopFreights < ActiveRecord::Migration
  def change
    add_column :shop_freights, :start_position, :string
  end
end
