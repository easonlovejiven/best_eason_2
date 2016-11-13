class Shop::DynamicComment < ActiveRecord::Base
  include Redis::Objects

  belongs_to :dynamic, class_name: "Shop::TopicDynamic", foreign_key: :dynamic_id
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  scope :son_comments_by, ->(parent_id){where(parent_id: parent_id)}

  validates_presence_of :content
  validates_presence_of :user_id

  after_create :update_shop_topics_participate_count

  def update_shop_topics_participate_count
    topic = self.dynamic.topic
    participator = topic.participator.increment
    topic.topic_comment_count.increment
    self.dynamic.participator.increment
  end
end
