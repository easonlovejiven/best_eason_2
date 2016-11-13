class CreateCoreSigns < ActiveRecord::Migration
  def change
    create_table :core_signs do |t|
      t.integer :user_id
      t.integer :time
      t.date :sign_at
      t.boolean :active

      t.timestamps null: false
    end
  end
end
