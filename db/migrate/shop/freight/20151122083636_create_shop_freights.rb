class CreateShopFreights < ActiveRecord::Migration
  def change
    create_table :shop_freights do |t|
      t.integer :freight_template_id
      t.string :destination #目的地
      t.boolean :active, default: true
      t.integer :frist_item, default: 1 #首件
      t.integer :reforwarding_item, default: 1 #续件
      t.decimal :first_fee, precision: 8, scale: 2, default: 0.0#首费
      t.decimal :reforwarding_fee, precision: 8, scale: 2, default: 0.0#续费
      t.boolean :id_delivery, default: false #是否支持配送

      t.timestamps null: false
    end
  end
end
