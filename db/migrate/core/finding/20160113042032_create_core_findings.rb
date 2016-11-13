class CreateCoreFindings < ActiveRecord::Migration
  def change
    create_table :core_findings do |t|
      t.string :title
      t.string :url
      t.string :pic
      t.text :description
      t.integer  :creator_id
      t.integer  :updater_id
      t.boolean :published, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_column :manage_roles, :core_finding, :integer, default: 0
  end
end
