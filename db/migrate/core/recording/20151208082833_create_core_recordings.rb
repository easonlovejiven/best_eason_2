class CreateCoreRecordings < ActiveRecord::Migration
  def change
    create_table :core_recordings do |t|
      t.string :name
      t.integer :user_id
      t.string :genre
      t.integer :count, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.integer :lock_version, default: 0, null: false
      t.timestamps null: false
    end
    add_column :manage_roles, :core_recording, :integer, default: 0
    add_index :core_recordings, [:active, :name, :genre], name: "by_name_and_genre"
  end
end
