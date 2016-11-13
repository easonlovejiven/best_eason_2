class AddShopFreightTemplateIdToShopEvents < ActiveRecord::Migration
  def change
    add_column :shop_events, :shop_freight_template_id, :integer
    add_column :shop_events, :need_freight, :boolean, default: false
  end
end
