class Qa::Question < ActiveRecord::Base
  # mount_uploader :pic, CorePicUploader
  validates :title, length: { maximum: 30, too_long: "最多输入30个文字" }
  has_many :answers, dependent: :destroy, class_name: Qa::Answer
  belongs_to :answer, class_name: Qa::Answer

  accepts_nested_attributes_for :answers, allow_destroy: true, limit: 5, reject_if: proc { |attributes| attributes['content'].blank? }
  validates :answers, :presence => true
  validate :answers_correct


  def answers_correct
    errors.add(:base, "请选择一个正确答案") if answers.reject(&:right).length != answers.length - 1
  end

  def picture_url
    pic.present? ? "http://#{Settings.qiniu["host"]}/#{pic}" : "http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png"
  end
end
