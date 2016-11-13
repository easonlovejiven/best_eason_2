class AddColumnResourceTypeToShopExtInfoVulues < ActiveRecord::Migration
  def change
    add_column :shop_ext_info_values, :resource_type, :string
  end
end
