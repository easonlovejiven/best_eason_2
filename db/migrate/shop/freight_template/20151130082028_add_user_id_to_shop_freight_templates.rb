class AddUserIdToShopFreightTemplates < ActiveRecord::Migration
  def change
    add_column :shop_freight_templates, :user_id, :integer
  end
end
