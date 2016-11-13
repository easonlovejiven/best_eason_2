class AddStartPositionToShopFreightTemplates < ActiveRecord::Migration
  def change
    add_column :shop_freight_templates, :start_position, :string
  end
end
