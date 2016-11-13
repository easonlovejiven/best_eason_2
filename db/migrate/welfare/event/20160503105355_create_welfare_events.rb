class CreateWelfareEvents < ActiveRecord::Migration
  def change
    create_table :welfare_events do |t|
      t.integer :user_id
      t.string :title
      t.string :descripe_key
      t.text :description
      t.datetime :sale_start_at
      t.datetime :sale_end_at
      t.string :address
      t.string :mobile
      t.string :star_list

      t.boolean  :active, default: true, null: false
      t.datetime :destroyed_at
      t.integer  :creator_id
			t.integer  :updater_id
			t.integer  :lock_version, default: 0,    null: false

      t.timestamps null: false
    end
  end
end
