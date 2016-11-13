class CreateCoreIdentities < ActiveRecord::Migration
  def change
    create_table :core_identities do |t|
      t.integer :user_id
      t.string :name
      t.string :org_name
      t.string :org_pic
      t.string :id_pic
      t.string :related_ids
      t.text :description
      t.boolean :is_org, null: false, default: false
      t.string :status
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end
  end
end
