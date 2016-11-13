class AddColumnAnswerIdToQaQuestions < ActiveRecord::Migration
  def change
    add_column :qa_questions, :answer_id, :integer
  end
end
