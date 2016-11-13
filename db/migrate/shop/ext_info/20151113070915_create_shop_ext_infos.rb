class CreateShopExtInfos < ActiveRecord::Migration
  def change
    create_table :shop_ext_infos do |t|
      t.string :title
      t.integer :event_id
      t.datetime :deleted_at
      t.boolean :require

      t.timestamps null: false
    end
  end
end
