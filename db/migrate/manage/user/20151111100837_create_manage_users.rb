class CreateManageUsers < ActiveRecord::Migration
  def change
    create_table :manage_users do |t|
      t.string :pic
      t.string :name
      t.string :sex
      t.string :birthday
      t.string :level
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      
      t.timestamps null: false
    end
  end
end
