class CreateQaQuestions < ActiveRecord::Migration
  def change
    create_table :qa_questions do |t|
      t.integer :poster_id
      t.string :title
      t.string :pic
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
