class Core::Star < ActiveRecord::Base
  searchkick
  acts_as_followable
  include Redis::Objects

  mount_uploader :pic, CorePicUploader
  mount_uploader :cover, CorePicUploader
  hash_key :friendship
  #validates :name, uniqueness: true, if: :is_active?
  before_create :validate_name, message: "名字不能重复"
  validates :description, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :works, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :acting, length: { maximum: 5000, too_long: "最多输入5000个文字" }

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"
  has_many :shop_task_stars, class_name: "Shop::TaskStar", foreign_key: :core_star_id
  has_many :shop_tasks, through: :shop_task_stars
  belongs_to :org, -> { where(active: true, identity: 3) }, class_name: Core::User, foreign_key: "org_id"

  scope :active, -> { where(active: true) }
  scope :except_omei, -> { where("id != 423") }
  scope :published, -> { active.where(published: true).order(position: :desc) }
  scope :populars, -> { active.order("participants desc, position desc, name desc, updated_at desc") }
  enum category: %w(china japan_korea europe_america other)#{'华语' => 0, '日韩' => 1, '欧美' => 2, '其他' => 3}#

  def picture_url
    pic.blank? ? 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png' : pic.url.present? ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png'
  end

  def validate_name
    #active 是当前变量的状态 只有在创建的时候进行验证
    if Core::Star.find_by(active: true, name: name).present?
      self.errors.add :base, "名字不能重复"
      return false
    else
      return true
    end
  end

  def app_picture_url
    pic.blank? ? 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png' : pic.app_pic.present? ? "http://#{Settings.qiniu["host"]}/#{pic.app_pic.try(:current_path)}" : 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png'
  end

  def fans_total
    self.fans_count + self.followers_user_count
  end

  def follow_key
    "#{model_name.cache_key}/#{id}"
  end

  def orgs_and_fans
    Core::User.active.where(id: ([org_id]+JSON.parse(related_ids.to_s).to_a.reject(&:blank?).map(&:to_i)).uniq.compact)
  end

  cattr_accessor :manage_fields
  self.manage_fields = %w[name nickname cover pic sign description company category works acting org_id related_ids position participants fans_count]<< { related_ids: [] }
end
