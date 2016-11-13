class CreateCoreHotRecords < ActiveRecord::Migration
  def change
    create_table :core_hot_records do |t|
      t.string :name
      t.string :synonym
      t.integer :position
      t.integer :creator_id
      t.integer :updater_id
      t.boolean :active, default: true
      t.boolean :published, default: true

      t.timestamps null: false
    end
  end
end
