class Qa::Poster < ActiveRecord::Base
  include ActAsActivable
  include Shop::TaskHelper
  include Redis::Objects

  counter :participator

  validates :title, length: { maximum: 30, too_long: "最多输入30个文字" }

  has_many :questions, dependent: :destroy, class_name: Qa::Question
  has_one :shop_task, as: :shop, class_name: "Shop::Task"
  has_many :awards, as: :task, class_name: Core::TaskAward
  belongs_to :user, class_name: Core::User
  accepts_nested_attributes_for :questions, allow_destroy: true, limit: 6, reject_if: proc { |attributes| attributes['title'].blank? }

  def cover_pic
    questions.tries(:first, :picture_url)
  end
end
