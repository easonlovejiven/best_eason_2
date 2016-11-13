class Shop::VoteOption < ActiveRecord::Base
  include ActAsActivable #多个model重用方法module
  include Redis::Objects
  counter :vote_count

  belongs_to :voteable, polymorphic: true
  has_many :vote_results, class_name: "Shop::VoteResult", foreign_key: :shop_vote_option_id, dependent: :destroy

  validates_presence_of :user_id, message: "用户id必填"

  validate :validate_content
  def validate_content
    errors.add(:content, "投票选项必填") if (content || "").size == 0
  end

end
