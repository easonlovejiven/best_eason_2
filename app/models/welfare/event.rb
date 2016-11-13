class Welfare::Event < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module
  include Redis::Objects
  include Shop::TaskHelper

  counter :participator
  validates :description, length: { maximum: 15000, too_long: "最多输入15000个文字" }
  validates :title, length: { maximum: 40, too_long: "最多输入40个文字" }
  validates :address, length: { maximum: 20, too_long: "最多输入20个文字" }
  validates :mobile, length: { maximum: 30, too_long: "最多输入30个数字" }

  has_many :expens, ->{where(active: true)}, as: :resource, dependent: :destroy, class_name: 'Core::Expen'
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  has_many :ext_infos, as: :task, class_name: 'Shop::ExtInfo', dependent: :destroy #shop_ext_infos 多态关联多个表 商品 活动 应援等等
  has_many :ticket_types, as: :task, class_name: 'Shop::TicketType', dependent: :destroy
  has_one :shop_task, as: :shop, class_name: "Shop::Task"
  validates_uniqueness_of :title, :scope => [:active, :user_id, :mobile, :star_list], message: "操作失败。原因：名称重复，该账号已发布过或在草稿箱里有同名的任务/福利。请修改后重试。"

  validates_presence_of :title
  validates_presence_of :description
  validates_presence_of :mobile
  validates_presence_of :star_list
  validates_presence_of :ticket_types
  validates_presence_of :user_id

  accepts_nested_attributes_for :ext_infos, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :ticket_types, allow_destroy: true, reject_if: :all_blank


  cattr_accessor :manage_fields

  def manage_fields
    ticket_types_attributes = %w{ id _destroy category second_category category_id task_id task_type ticket_limit is_limit original_fee fee is_each_limit each_limit}
    ext_infos_attributes = %w{ id _destroy title task_id require task_type }
    if self.id.blank?
      ticket_types_attributes -= ["id"]
      ext_infos_attributes -= ["id"]
    end
    %w[ id user_id title descripe_key description sale_start_at sale_end_at start_at end_at address mobile star_list] << {star_list: [], ticket_types_attributes: ticket_types_attributes, ext_infos_attributes: ext_infos_attributes}
  end

  def descripe_key_url
    descripe_key.present? ? ("http://" + Settings.qiniu["host"] + "/" + descripe_key).to_s : ""
  end

  def cover_pic
    descripe_key_url
  end

  def expens_size
    Rails.cache.fetch("expens_size_by_task_id_#{self.id}_and_task_type_expen_events", expires_in: 5.minutes) do
      self.expens.size
    end
  end

  def sum_fee
    Rails.cache.fetch("sum_fee_by_task_id_#{self.id}_and_task_type_expen_events", expires_in: 5.minutes) do
      self.expens.map(&:amount).sum.to_f.round(2)
    end
  end

end
