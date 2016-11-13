class ChangeColumnDescripe2ToShopEvents < ActiveRecord::Migration
  def change
    change_column :shop_events, :descripe2, :text
    change_column :shop_products, :descripe2, :text
    change_column :shop_fundings, :descripe2, :text
  end
end
