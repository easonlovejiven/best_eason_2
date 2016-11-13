class AddCreatorIdToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :updater_id, :integer
  end
end
