class CreateQaAnswers < ActiveRecord::Migration
  def change
    create_table :qa_answers do |t|
      t.integer :question_id
      t.text :content
      t.boolean :right, default: false, null: false
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
