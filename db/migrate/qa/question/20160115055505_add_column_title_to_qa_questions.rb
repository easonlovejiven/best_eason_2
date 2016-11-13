class AddColumnTitleToQaQuestions < ActiveRecord::Migration
  def change
    change_column :qa_questions, :title, :text
  end
end
