class Qa::Answer < ActiveRecord::Base
  belongs_to :question, class_name: Qa::Question
  
  validates :right, uniqueness: { scope: [:question_id] }

  after_save do |record|
    question.update(answer_id: record.id) if question.answer_id != question.id && right?
  end
end
