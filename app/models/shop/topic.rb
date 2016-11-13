##
# = 任务 话题 表
#
# == Fields
#
# user_id 发布人
# creator_id 创建人（运营人员）
#
# == Indexes
#

class Shop::Topic < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module
  include Shop::TaskHelper
  include Redis::Objects

  validates :description, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :kinder_description, length: { maximum: 15000, too_long: "最多输入15000个文字" }
  validates :title, length: { maximum: 30, too_long: "最多输入30个文字" }

  sorted_set :topic_dynamic_state #动态每人的参与数量集合
  sorted_set :dynamic_comment_state #动态评论每人参与数量集合
  counter :participator
  counter :topic_comment_count
  counter :topic_like_count

  mount_uploader :cover1, ShopTopicUploader
  validates_presence_of :title
  # validates :title, uniqueness: true
  validates_presence_of :description
  validates_presence_of :cover1, unless: :key
  validates_presence_of :key, unless: :cover1
  validates_presence_of :star_list

  has_many :dynamics, class_name: "Shop::TopicDynamic", foreign_key: :shop_topic_id #该话题的所有动态
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  belongs_to :creator, class_name: "Core::User", foreign_key: :creator_id
  has_one :shop_task, as: :shop, class_name: "Shop::Task"

  before_save :update_title

  def update_title
    self.title = "#" + self.title + "#" unless self.title[0] == "#" && self.title[-1] == "#"
  end

  def picture_url
    key.blank? ? (cover1.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover1.try(:current_path)}" : nil) : cover1.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover1.try(:current_path)}" : key_url #前端发布后即不可修改
  end

  def key=(val)
    super CGI.escape(CGI.unescape(val.to_s))
  end

  def cover_pic
    picture_url
  end

  def key_url
    ("http://" + Settings.qiniu["host"] + "/" + key).to_s
  end

  cattr_accessor :manage_fields do
    %w[ id guide title description kinder_description cover1 cover1_cache user_id is_share key creator_id ] << {star_list: []}
  end
end
