class CreateCoreKeywords < ActiveRecord::Migration
  def change
    create_table :core_keywords do |t|
    	t.string   :name
    	t.boolean  :active, default: true,  null: false
    	t.datetime :destroyed_at
    	t.integer :creator_id
    	t.integer :updater_id
      	t.timestamps null: false
    end
    add_index :core_keywords, [:active, :name], name: "by_active_and_name"
  end
end
