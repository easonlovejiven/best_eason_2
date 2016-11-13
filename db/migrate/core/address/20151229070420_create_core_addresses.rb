class CreateCoreAddresses < ActiveRecord::Migration
  def change
    create_table :core_addresses do |t|
      t.integer :user_id
      t.string :mobile
      t.string :phone
      t.string :zip_code
      t.integer :province_id
      t.integer :city_id
      t.integer :district_id
      t.string :address
      t.string :addressee
      t.boolean :active, default: true
      t.boolean :default, default: false #默认地址

      t.timestamps null: false
    end
  end
end
