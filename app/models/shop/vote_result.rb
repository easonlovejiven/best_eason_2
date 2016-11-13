class Shop::VoteResult < ActiveRecord::Base
  belongs_to :vote_option, class_name: "Shop::VoteOption", foreign_key: :shop_vote_option_id
  belongs_to :resource, polymorphic: true

  validates_presence_of :shop_vote_option_id, message: "投票选项id必填"
  validates_presence_of :user_id, message: "用户id必填"

  validates_uniqueness_of :user_id, :scope => [:resource_id, :resource_type], if: Proc.new { |record| record.active? }, message: "你已经参与过投票了！"

  after_create :update_vote_cout

  def update_vote_cout
    self.vote_option.vote_count.increment
  end
end
