class CreateWelfareLetters < ActiveRecord::Migration
  def change
    create_table :welfare_letters do |t|
      t.string :title
      t.integer :paper_id
      t.integer :receiver_id
      t.text :content
      t.string :signature
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
