class CreateCorePunches < ActiveRecord::Migration
  def change
    create_table :core_punches do |t|
      t.integer :user_id
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
