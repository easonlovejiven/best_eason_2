class AddIsShareToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :is_share, :boolean
    add_column :shop_fundings, :creator_id, :integer
  end
end
