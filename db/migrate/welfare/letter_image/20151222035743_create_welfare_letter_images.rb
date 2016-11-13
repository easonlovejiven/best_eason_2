class CreateWelfareLetterImages < ActiveRecord::Migration
  def change
    create_table :welfare_letter_images do |t|
      t.integer :letter_id
      t.string :key
      t.string :pic
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
