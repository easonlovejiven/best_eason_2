##
# = 核心 用户 表
#
# == Fields
#
# pic :: 用户图片
# name :: 姓名
# sex :: 性别
# birthday :: 生日
# level :: 用户等级
# role :: 未用
# identity :: 用户身份{'普通用户' => 0, '粉丝会' => 1, '机构' => 2}
# position :: 0
# verified_at :: 认证时间
# verified :: 是否认证用户
# creator_id :: 创建者（后台运营账号修改）
# updater_id :: 编辑者
# empirical_value :: 经验值
# obi :: o币
# signature :: 个性签名
# participants :: participants
# image_id :: 未用
# privacy :: 未用
# old_uid :: 在owhat2中 表users的id
# followers_user_count :: 关注数
# follow_user_count :: 粉丝数
# active? :: 有效？
#
# == Indexes
#
# name
#
class Core::User < ActiveRecord::Base
  searchkick
  include ActAsActivable
	include Redis::Objects
  include Core::UserHelper
  include Core::FeedHelper

  before_save :changed_verified_force_login

  def changed_verified_force_login
    self.account.reset_login_salt if verified_changed?
  end

  validates :signature, length: { maximum: 5000, too_long: "最多输入5000个文字" }

  lock :create_order_item #限购每人不得同时并发进行购买
  lock :create_dynamic #限购每人不得连续发送话题评论
  lock :like_dynamic #限购每人不得连续发送话题评论
  lock :create_welfare #限购每人购买的免费福利

	acts_as_followable
  acts_as_follower
  # mount_uploader :pic, CorePicUploader
	# Friendship
  # 数据结构: {'123': 2}
  # key: 关联用户ID
  # value: 1 => 单方－我关注对方；2 => 单方－对方关注我； 3 => 互相关注
  hash_key :friendship
  # counter :follow_user_count, default: 0 #粉丝数
  # counter :follower_user_count, default: 0 #关注数

	validates_inclusion_of       :sex, :in => ['male', 'female'], :allow_nil => true
  validates :identity, exclusion: { in: ['common'], message: '认证用户身份必须为 expert 或者 organization' }, if: :verified?
	belongs_to :account, foreign_key: "id"
  belongs_to :creator, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "updater_id"
  belongs_to :image, class_name: "Core::Image", foreign_key: "image_id"
  has_many :orders, class_name: "Shop::Order"
  has_many :order_items, class_name: "Shop::OrderItem"
  has_many :funding_orders, class_name: "Shop::FundingOrder"
  has_many :task_awards, as: :task, dependent: :destroy #任务奖励表
	has_many :shop_fundings, class_name: "Shop::Funding"
	has_many :shop_tasks, class_name: "Shop::Task"
  has_many :recordings
  has_many :exported_orders, as: :user, class_name: "Core::ExportedOrder", dependent: :destroy #导出订单列表
  has_one :cart, class_name: "Shop::Cart", dependent: :destroy, foreign_key: :uid #购物车
  has_many :addresses, -> { where active: true }, class_name: "Core::Address", foreign_key: :user_id #收货地址
  has_many :withdraw_orders, class_name: 'Core::WithdrawOrder', foreign_key: :requested_by
  has_one :sign, class_name: "Core::Sign", foreign_key: :user_id #签到表
  has_many :punches, class_name: "Core::Punch", foreign_key: :user_id #打卡
  has_many :expens, class_name: Core::Expen, foreign_key: :user_id
  has_many :freight_templates, as: :user, class_name: "Shop::FreightTemplate", dependent: :destroy #运费模板
  has_many :identities
  scope :active, -> { where(active: true) }
  scope :populars, -> { active.order("position desc, participants desc, updated_at desc") }

  def validate_user_name
    if active == true
      return {status: false, msg: "昵称不允许输入空格/回车"} if name.match(/[ \n\r]/)
      user = Core::User.where(name: self.name, active: true).where("id != ?", self.id)
      return {status: false, msg: "该昵称已存在!"} if user.present?
    end
    {status: true}
  end

  attr_accessor :phone, :email

  def phone
    self.account.try(:phone)
  end

  def email
    self.account.try(:email)
  end

  def update_with_phone_email(data)
    ret = false
    begin
      Core::User.transaction do
        self.update_attributes!(data)
        @account = self.account
        if data[:phone] != account.try(:phone) || data[:email] != account.try(:email)
          @account.update_attributes!(phone: data[:phone], email: data[:email])
        end
        ret = true
      end
    rescue StandardError => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    {ret: ret, msg: ret == false ? (self.errors.first.try(:last) || @account.errors.first.try(:last) || '更新失败，请检查所填内容') : ''}
  end

  enum identity: %w(common expert organization)#{'普通用户' => 0, '粉丝会' => 1, '机构' => 2}#

  def login_today(client_type, option = {})
    date = Time.now.to_date
    login = Core::Login.where(user_id: id, login_on: date).order(id: :desc).first
    case client_type
    when 'web'
      unless login.try(:client) == option[:client] && login.try(:ip_address) == option[:ip_address] && login.try(:user_agent) == option[:user_agent]
        Core::Login.create({
          user_id: id,
          login_on: date,
          ip_address: option[:ip_address],
          client: option[:client],
          user_agent: option[:user_agent]
        })
      end
    when 'app'
      unless login.try(:client) == option[:client] && login.try(:ip_address) == option[:ip_address] && login.try(:device_id) == option[:device_id] && login.try(:device_models) == option[:device_models] && login.try(:manufacturer) == option[:manufacturer] && login.try(:system_version) == option[:system_version]
        Core::Login.create({
          user_id: id,
          login_on: date,
          ip_address: option[:ip_address],
          client: option[:client],
          device_id: option[:device_id],
          device_models: option[:device_models],
          manufacturer: option[:manufacturer],
          system_version: option[:system_version]
        })
      end
    end
    account.last_login_on = date
    account.save if account.changed?
  end

  def task_count category
    if self.verified?
      self.shop_tasks.where('shop_tasks.category = ? ', category).size
    else
      if category == 'welfare'
        self.expens.count
      else
        0
      end
    end
  end


	def unfollow_and_update_cache(o_user)
    if stop_following(o_user)
      if o_user.is_a?(Core::User)
        if o_user.respond_to?(:following?) && o_user.following?(self)
          friendship[o_user.follow_key] = 2
          o_user.friendship[follow_key] = 1
        else
          friendship.delete(o_user.follow_key)
          o_user.friendship.delete(follow_key) if o_user.respond_to?(:friendship)
        end
      else
        o_user.friendship[o_user.follow_key] = 0
        self.friendship[o_user.follow_key] = 0
      end
      o_user.decrement!(:followers_user_count) if o_user.followers_user_count > 0 # 关注数-1
      self.decrement!(:follow_user_count) if self.follow_user_count > 0 # 关注者被关注数-1
    end
  end

  def follow_and_update_cache(o_user)
    if follow(o_user)
      if o_user.is_a?(Core::User)
        if o_user.respond_to?(:following?) && o_user.following?(self)
          friendship[o_user.follow_key] = 3
          o_user.friendship[follow_key] = 3
        else
          friendship[o_user.follow_key] = 1
          o_user.friendship[follow_key] = 2  if o_user.respond_to?(:friendship)
        end

      else
        friendship[o_user.follow_key] = 1
        o_user.friendship[o_user.follow_key] = 1
      end
      self.increment!(:follow_user_count)  # 关注数加1
      o_user.increment!(:followers_user_count) # 关注者被关注数加1
    end
  end

  def followers_count
    self.followers_user_count
  end

  def follow_count
    self.follow_user_count
  end

  def picture_url
    return pic.gsub(/\?.*/, "") if pic.to_s.match(/^http\:\/\//)
    pic.present? ? "http://#{Settings.qiniu["host"]}/#{pic}" : 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png'
  end

  def follow_status(user)
    case friendship[user.follow_key]
    when '3', '1'
      return true
    else
      return false
    end
  end

  def address
    addresses.where(is_default: true).first || addresses.first
  end

  def follow_key
    "#{model_name.cache_key}/#{id}"
  end

  def app_picture_url
    picture_url.present? ? picture_url.gsub(/\?.*/, "?imageMogr2/thumbnail/!50p") : ''
  end

  cattr_accessor :manage_fields do
    %w[ id pic name sex birthday level active role identity position verified_at verified participants phone email]
  end

  class << self
    def incr_redis_count(counter_name, user_id)
      $redis.incr "User:#{counter_name.to_s.camelize}:#{user_id}"
    end

    def decr_redis_count(counter_name, user_id)
      $redis.decr "User:#{counter_name.to_s.camelize}:#{user_id}"
    end
  end

  #GRADE_CONFIG = {等级 => [等级对应称谓, 需要经验, 升级奖励]}
  GRADE_CONFIG = {0 => ['打酱油', 0, 0], 5 => ['自带板凳', 5, 50], 10 => ['初级粉丝', 15, 50],
   15 => ['中级粉丝', 30, 100], 20 => ['高级粉丝', 50, 100], 25 => ['资深粉丝', 100, 150],
   30 => ['正式会员', 200, 150], 35 => ['核心会员', 500, 200], 40 => ['铁杆会员', 1000, 200],
   45 => ['银牌会员', 2000, 250], 50 => ['金牌会员', 3000, 250], 55 => ['钻石会员', 6000, 300], 60 => ['皇冠会员', 10000, 300],
   65 => ['知名人士', 15000, 350], 70 => ['人气楷模', 18000, 350], 75 => ['意见领袖', 30000, 400], 80 => ['粉丝元老', 60000, 400],
   85 => ['高阶元老', 70000, 450], 90 => ['资深元老', 80000, 450], 95 => ['荣耀元老', 90000, 500], 100 => ['粉丝之王', 100000, 500]
  }

  def current_level_name
    GRADE_CONFIG[self.level][0]
  end

  def next_level
    (self.level || 0) + 5
  end

  def next_level_need
    (GRADE_CONFIG[self.next_level] || [])[1] || 100000
  end

  def auto_share_status
    is_auto_share == nil ? 'null' : (is_auto_share == true ? 'yes' : 'no')
  end

  def weibo_auto_share_info
    connection = Core::Connection.where(account_id: self.id, site: 'weibo', active: true).first
    {
      auto_share_status: auto_share_status,
      has_weibo: connection.present?,
      token: connection.try(:token),
      identifier: connection.try(:identifier),
      weibo_token_active: connection.present? && connection.try(:token).present? && connection.try(:identifier).present? && connection.try(:expired_at).present? && (connection.try(:expired_at) > Time.now)
    }
  end
end
