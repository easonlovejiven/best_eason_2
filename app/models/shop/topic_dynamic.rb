class Shop::TopicDynamic < ActiveRecord::Base
  include ActAsActivable #多个model重用方法module
  include Redis::Objects
  counter :participator

  belongs_to :topic, class_name: "Shop::Topic", foreign_key: :shop_topic_id
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  has_many :comments, class_name: "Shop::DynamicComment", foreign_key: :dynamic_id #针对话题动态评论
  has_many :pictures, class_name: "Shop::Picture", as: :pictureable, dependent: :destroy
  has_many :vote_options, class_name: "Shop::VoteOption", as: :voteable, dependent: :destroy
  has_many :vote_results, class_name: "Shop::VoteResult", as: :resource, dependent: :destroy
  has_many :videos, class_name: "Shop::Video", as: :videoable, dependent: :destroy

  validates :like_count, numericality: {only_integer: true, less_than: 10000, greater_than_or_equal_to: 0, message: "小于10000" }

  validates_presence_of :content
  validates_presence_of :user_id

  accepts_nested_attributes_for :pictures, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :vote_options, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :videos, allow_destroy: true, reject_if: :all_blank

  validate :validate_vote_option_count
  def validate_vote_option_count
    errors.add(:vote_options, "请不要少于两个投票选项") if vote_options.present? && vote_options.size < 2
  end

  after_create :update_shop_topics_participate_count
  after_update :update_shop_topic_dynamics_participate_count

  cattr_accessor :manage_fields do
    %w[ id content user_id shop_topic_id comment_count like_count foward_count ] << {pictures_attributes: %w{ id pictureable_id pictureable_type cover key user_id}, videos_attributes: %w{id videoable_id videoable_typekey user_id }, votes_attributes: %w{id voteable_id voteable_type content user_id }}
  end

  def update_shop_topics_participate_count
    topic = Shop::Topic.find_by(id: shop_topic_id)
    participator = topic.participator.increment
    topic.topic_dynamic_state["#{self.user_id}"] += 1
  end

  def update_shop_topic_dynamics_participate_count
    self.participator.increment
  end

end
