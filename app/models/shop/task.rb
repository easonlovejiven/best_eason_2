##
# = 任务 总任务 表
#
# == Fields
#
# user_id 发布人
# creator_id 创建人（运营人员）
#
# == Indexes
#
class Shop::Task < ActiveRecord::Base
  searchkick callbacks: :async
  # searchkick mappings: {
  #   shop_task: {
  #     properties: {
  #       title: {type: "string", analyzer: "searchkick_search"},
  #       description: {type: "string", analyzer: "searchkick_search"}
  #     }
  #   }
  # }
  include Redis::Objects
  include Core::TaskHelper
  sorted_set :task_state
  sorted_set :share_state

  after_update :update_shop
  after_save :clear_index_cache
  def clear_index_cache
    Rails.cache.delete("index_page_tasks")
    kind = {
      "welfare" => {"Welfare::Event" => "event", "Welfare::Product" => "product", "Welfare::Letter" => "letter", "Welfare::Voice" => "voice"},
      "task" => {"Shop::Event" => "events", "Shop::Product" => "events", "Shop::Funding" => "fundings", "Shop::Topic" => "topics", "Qa::Poster" => "questions", "Shop::Subject" => "subjects", "Shop::Media" => "media"}
    }
    case self.category
    when "welfare"
      Rails.cache.delete("index_page_welfares_all")
      Rails.cache.delete("index_page_welfares_#{kind[self.category][self.shop_type]}")
    when "task"
      Rails.cache.delete("index_page_tasks_all")
      Rails.cache.delete("index_page_tasks_#{kind[self.category][self.shop_type]}")
    end
  end

  validates :description, length: { maximum: 15000, too_long: "最多输入15000个文字" }

  belongs_to :shop, polymorphic: true
  has_many :shop_task_stars, class_name: "Shop::TaskStar", foreign_key: :shop_task_id
  has_many :expens, class_name: Core::Expen, foreign_key: :task_id
  has_many :core_stars, through: :shop_task_stars
  belongs_to :user, class_name: Core::User
  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"

  scope :active, -> { where(active: true) }
  scope :published, -> { active.where(published: true) }
  scope :unpublished, -> { active.where(published: false) }
  scope :is_top, -> { active.where(is_top: true) }
  scope :untop, -> { active.where("is_top IS NOT true") }
  scope :expired, -> { where("expired_at > ? OR expired_at IS NULL", Time.now.to_s(:db)) }
  scope :unexpired, -> { where("expired_at < ?", Time.now.to_s(:db)) }
  scope :populars, -> { active.expired.order("is_top desc, position desc, participants desc, updated_at desc") }
  scope :newests, -> { active.order("created_at desc") }
  scope :tops, -> { active.expired.order("is_top desc, created_at desc") }
  scope :hots, -> { active.order("participants desc") }
  scope :completed, -> { populars.where(is_complete: false).order("created_at desc") }
  scope :letters, -> { active.where(shop_type: 'Welfare::Letter')}
  scope :topics, -> { active.where(shop_type: 'Shop::Topic')}
  scope :fundings, -> { active.where(shop_type: 'Shop::Funding')}
  scope :products, -> { active.where(shop_type: 'Shop::Product')}
  scope :task_events, -> { active.where(shop_type: 'Shop::Event')}
  scope :events, -> { active.where(shop_type: ['Shop::Event', 'Shop::Product'])}
  scope :questions, -> { active.where(shop_type: 'Qa::Poster')}
  scope :subjects, -> { active.where(shop_type: 'Shop::Subject')}
  scope :media, -> { active.where(shop_type: 'Shop::Media')}
  scope :welfares, -> { published.where(category: 'welfare')}
  scope :voices, -> { active.where(shop_type: 'Welfare::Voice')}
  scope :welfare_events, -> { active.where(shop_type: 'Welfare::Event')}
  scope :welfare_products, -> { active.where(shop_type: 'Welfare::Product')}
  scope :tasks, -> { published.where(category: 'task')}
  scope :today_update, ->(time) { active.where("created_at >= ?", time) }
  scope :need_preview, -> { active.where("shop_type != 'Welfare::Voice'")}

  validates_presence_of :title
  validates_presence_of :star_list

  def is_available?
    active && published
  end


  def payment_obi(user, options={})
    self.task_state["#{self.shop_type}:#{user.id}"] = 1  if self.shop_type == 'Welfare::Letter' || self.shop_type == 'Welfare::Voice'
    ExpenWorker.perform_async(id, user.id, options)
  end

  def get_obi(user, options={})
    task_state["#{shop_type}:#{user.id}"] += 1 unless options[:type] == 'share'
    if shop_type == "Shop::Media" || !self.tries(:shop, :is_share)
      user.feeds.remove(id)
    else
      user.feeds.remove(id) if share_state["#{shop_type}:#{user.id}"] > 0 && task_state["#{shop_type}:#{user.id}"] > 0
    end
  end

  #是否参加过该话题
  def participate_topic(user_id)
    if task_state["#{shop_type}:#{user_id}"].to_i > 0
      task_state["#{shop_type}:#{user_id}"] += 1
    else
      task_state["#{shop_type}:#{user_id}"] = 1
      user.feeds.remove(id)
    end
  end

  def participate_subject(user_id)
    if task_state["#{shop_type}:#{user_id}"].to_i > 0
      task_state["#{shop_type}:#{user_id}"] += 1
    else
      task_state["#{shop_type}:#{user_id}"] = 1
      user.feeds.remove(id)
    end
  end
  # 真实参与人数数据
  def participator
    case shop_type
    when 'Shop::Event', 'Shop::Product', 'Shop::Funding', 'Welfare::Event', 'Welfare::Product'
      self.shop ? self.shop.ticket_types.map{|t| t.participator.value }.sum : 0
    else
      self.shop.participator.value
    end
  end

  def list_pic
    pic.present? ? pic.gsub(/\?.*/, "")+"?imageMogr2/thumbnail/!80p" : ''
  end

  def web_pic(list=true)
    if list
      pic.present? ? pic.gsub(/\?.*/, "") : 'http://qimage.owhat.cn/9.png'
    else
      pic.present? ? pic.gsub(/\?.*/, "")+"?imageMogr2/auto-orient/thumbnail/!640x480r/gravity/North/crop/640x480" : 'http://qimage.owhat.cn/9.png'
    end
  end

  def update_shop
    if active_changed?
      self.shop.update(active: self.active)
    end
  end

  cattr_accessor :manage_fields
  self.manage_fields = %w[title guide description participants position is_top]
  CATEGORY = {'letter' => 'Welfare::Letter', 'voice'=>'Welfare::Voice', 'event'=>'Welfare::Event', 'product'=>'Welfare::Product'}

  CATEGORY_PATH = {'Welfare::Letter' => 'welfare/letters', 'Welfare::Voice' => 'welfare/voices', 'Welfare::Event' => 'welfare/events', 'Welfare::Product' => 'welfare/products', 'Shop::Event' => 'shop/events', 'Shop::Product' => 'shop/products', 'Shop::Funding' => 'shop/fundings', 'Qa::Poster' => 'qa/posters', 'Shop::Topic' => 'shop/topics', 'Shop::Subject' => 'shop/subjects', 'Shop::Media' => 'shop/medias'}
  SHOP_TYPE = {'Shop::Event' => '活动', 'Shop::Product' => '商品', 'Shop::Funding' => '应援', 'Welfare::Letter' => '书信', 'Welfare::Voice' => '语音', 'Welfare::Event' => '福利活动', 'Welfare::Product' => '福利商品', 'Qa::Poster' => '问答', 'Shop::Topic' => '话题', 'Shop::Subject' => '直播', 'Shop::Media' => '精选'}
end
