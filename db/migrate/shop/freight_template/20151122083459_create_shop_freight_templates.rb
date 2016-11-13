class CreateShopFreightTemplates < ActiveRecord::Migration
  def change
    create_table :shop_freight_templates do |t|
      t.string :name
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
