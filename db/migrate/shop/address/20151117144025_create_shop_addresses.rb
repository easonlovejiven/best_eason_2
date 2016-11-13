class CreateShopAddresses < ActiveRecord::Migration
  def change
    create_table :shop_addresses do |t|
      t.string :mobile
      t.integer :user_id
      t.string   :zip_code,    limit: 255
      t.integer  :province_id, limit: 4
      t.integer  :city_id,     limit: 4
      t.integer  :district_id,     limit: 4
      t.string   :address
      t.string   :receive_name
      t.boolean  :dafault #是否默认

      t.timestamps null: false
    end
  end
end
