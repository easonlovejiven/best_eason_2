class AddResultDescribeToShopFundings < ActiveRecord::Migration
  def change
    add_column :shop_fundings, :result_describe, :text
  end
end
