class Core::WithdrawOrder < ActiveRecord::Base
  include ActAsActivable

  belongs_to :requestor, class_name: 'Core::User', foreign_key: :requested_by
  belongs_to :verifier, class_name: 'Manage::User', foreign_key: :verified_by
  belongs_to :task, polymorphic: true
  # has_one :exported_order, class_name: 'Core::ExportedOrder', foreign_key: :core_exported_order_id
  has_many :pictures, class_name: "Shop::Picture", as: :pictureable, dependent: :destroy

  accepts_nested_attributes_for :pictures, allow_destroy: true, reject_if: :all_blank

  enum status: { pending: 1, rejected: 2, paid: 3, canceled: -1 }

  validates :receiver_name, presence: true
  validates_format_of :mobile, with: /\A1[3|4|5|7|8]\d{9}\z/, if: -> { mobile.present? }
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: -> { email.present? }
  validates :receiver_account, presence: true
  validates_uniqueness_of :task_id, :scope => [:task_type, :requested_by, :requested_at, :status], if: Proc.new { |record| record.active? }, message: "请不要重复提交"
  # validates :requested_at, uniqueness: true

  scope :pending, -> { where("status = 1") }

  cattr_accessor :manage_fields do
    %w[ id amount tickets_count receiver_name receiver_account bank_name requestor_remark requested_by requested_at verifier_remark verified_at verified_by cut_off_at mobile email status task_id task_type ]
  end

  def status_name
    if pending?
      "待审核"
    elsif rejected?
      "审核不通过"
    elsif paid?
      "已支付"
    elsif canceled?
      "已取消"
    end
  end

  private
  def bank_name_exist
    errors.add(:bank_name, "请填开户行名称") if !self.receiver_account.include?('@') && self.bank_name.blank?
  end
end
