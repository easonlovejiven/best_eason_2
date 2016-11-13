class AddColumnUserTypeToShopFreightTemplates < ActiveRecord::Migration
  def change
    add_column :shop_freight_templates, :user_type, :string
  end
end
