class CreateQaPosters < ActiveRecord::Migration
  def change
    create_table :qa_posters do |t|
      t.text :title
      t.string :pic
      t.integer :user_id
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
