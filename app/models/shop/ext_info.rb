#活动报名表单
class Shop::ExtInfo < ActiveRecord::Base
  include ActAsActivable
  belongs_to :task, polymorphic: true
  has_many :ext_info_values, class_name: "Shop::ExtInfoValue", foreign_key: :ext_info_id
  validates :title, length: { maximum: 20, too_long: "最多输入20个文字" }
  validates_presence_of :title, message: "报名所需信息标题不可为空"

  validate :validate_emoji
  def validate_emoji
    errors.add(:title, "报名信息部分不可以含表情及特殊符号哟") if (title || "").judge_emoji
  end
end
