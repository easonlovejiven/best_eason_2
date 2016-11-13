class Shop::Event < ActiveRecord::Base
  include ActAsActivable
  include Shop::TaskHelper
  include Redis::Objects

  counter :participator #参与活动人数

  mount_uploader :cover1, ShopEventUploader
  mount_uploader :cover2, ShopEventUploader
  mount_uploader :cover3, ShopEventUploader
  mount_uploader :descripe_cover, ShopEventUploader

  validates :description, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :descripe2, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :title, length: { maximum: 40, too_long: "最多输入40个文字" }
  validates :address, length: { maximum: 20, too_long: "最多输入20个文字" }
  validates :mobile, length: { maximum: 30, too_long: "最多输入30个数字" }

  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  belongs_to :creator, class_name: "Core::User", foreign_key: :creator_id
  has_many :ext_infos, as: :task, dependent: :destroy #shop_ext_infos 多态关联多个表 商品 活动 应援等等
  has_many :ticket_types, as: :task, dependent: :destroy
  has_many :order_items, ->{where(active: true)}, as: :owhat_product, dependent: :destroy
  has_one :withdraw_order, ->{where(active: true)}, class_name: 'Core::WithdrawOrder', as: :task, dependent: :destroy#提现申请多态
  has_one :shop_task, as: :shop, class_name: "Shop::Task"
  belongs_to :freight_template, class_name: "Shop::FreightTemplate", foreign_key: :freight_template_id

  validates_uniqueness_of :title, :scope => [:active, :user_id, :mobile, :star_list], message: "操作失败。原因：名称重复，该账号已发布过或在草稿箱里有同名的任务/福利。请修改后重试。"

  validates_presence_of :title
  validates_presence_of :description
  validates_presence_of :cover1, unless: :key1
  validates_presence_of :mobile
  validates_presence_of :star_list
  validates_presence_of :user_id
  validates_presence_of :ticket_types, message: "价格信息为必填！"
  # validates :title, uniqueness: true
  # validates_presence_of :start_at #活动开始时间
  # validates_presence_of :end_at #活动结束时间
  # validates_presence_of :sale_start_at #购票开始时间
  # validates_presence_of :sale_end_at #购票结束时间

  validates :title, :length => { :maximum => 100}
  validates :mobile, numericality: { only_integer: true }

  accepts_nested_attributes_for :ext_infos, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :ticket_types, allow_destroy: true, reject_if: :all_blank

  enum product_type: { '活动' => 'event', '商品' => 'goods', '应援' => 'funding' }
  enum page_sort: %w(上文下图 上图下文 只图 只文)

  scope :by_title, ->(title){default(title: title)}

  cattr_accessor :manage_fields

  def manage_fields
    ticket_types_attributes = %w{ id category second_category category_id task_id task_type ticket_limit is_limit original_fee fee is_each_limit each_limit _destroy}
    ext_infos_attributes = %w{ id title task_id require task_type _destroy}
    if self.id.blank?
      ticket_types_attributes -= ["id"]
      ext_infos_attributes -= ["id"]
    end
    %w[ id is_rush guide shop_category title funding_target description descripe_cover descripe2 cover1 cover2 key1 key2 key3 cover3 start_at end_at sale_start_at sale_end_at address mobile star_list user_id creator_id is_share free is_need_express freight_template_id ] << {star_list: [], ticket_types_attributes: ticket_types_attributes, ext_infos_attributes: ext_infos_attributes}
  end

  def descripe_cover_url
    descripe_key.blank? ? (descripe_cover.url.present? ? "http://#{Settings.qiniu["host"]}/#{descripe_cover.try(:current_path)}" : nil) : descripe_cover.url.present? ? "http://#{Settings.qiniu["host"]}/#{descripe_cover.try(:current_path)}" : descripe_key_url
  end

  def cover_url(index)
    eval("key#{index}").blank? ? (eval("cover#{index}").url.present? ? "http://#{Settings.qiniu["host"]}/#{eval("cover#{index}").current_path}" : nil) : key_url(index)
  end

  def cover_pic
    cover_url(1)
  end

  def descripe_key_url
    ("http://" + Settings.qiniu["host"] + "/" + descripe_key).to_s
  end

  def key_url(index)
    ("http://" + Settings.qiniu["host"] + "/" + eval("key#{index}")).to_s
  end

  def order_items_size
    Rails.cache.fetch("order_items_size_by_task_id_#{self.id}_and_task_type_shop_events", expires_in: 5.minutes) do
    Shop::OrderItem.where(owhat_product_id:self.id, owhat_product_type: self.class.to_s).group(:status).count
    end
  end

  def sum_fee
    Rails.cache.fetch("sum_fee_by_task_id_#{self.id}_and_task_type_shop_events", expires_in: 5.minutes) do
      self.order_items.where(status: 2).map(&:payment).sum.to_f.round(2)
    end
  end

  def unwithdraw_order_fee
    Rails.cache.fetch("unwithdraw_order_fee_by_task_id_#{self.id}_and_task_type_shop_events", expires_in: 5.minutes) do
      self.order_items.where(status: 2).map(&:payment).sum.to_f.round(2) - Core::WithdrawOrder.where(status: 3, task_id: self.id, task_type: "Shop::Event").map(&:amount).sum.to_f.round(2)
    end
  end
 end
