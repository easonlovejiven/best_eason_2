class CreateManageGrants < ActiveRecord::Migration
  def change
    create_table :manage_grants do |t|
    	t.integer  :editor_id
    	t.integer  :role_id
    	t.integer  :updater_id
    	t.integer  :creator_id
    	t.boolean  :active,       default: true, null: false
    	t.integer  :lock_version, default: 0,    null: false
      t.timestamps null: false
    end
    add_index :manage_grants, [:active, :editor_id, :role_id], name: "by_active_and_editor_id_and_role_id"
  end
end
