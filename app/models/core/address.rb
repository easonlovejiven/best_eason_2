class Core::Address < ActiveRecord::Base
  include ActAsActivable
  include Core::AddressAble

  belongs_to :user, class_name: "Core::User", foreign_key: "user_id"

  validates :user_id, :mobile, :province_id, :city_id, :address, :addressee, presence: true
  validates :address, :length => { :maximum => 200}
  validates :addressee, :length => { :maximum => 20}
  validates :mobile, numericality: { only_integer: true }, if: :unless_delete?
  validates :zip_code, numericality: { only_integer: true }, if: Proc.new { |record| record.active == true && record.zip_code.present? }

  validate :validate_emoji

  def validate_emoji
    errors.add(:address, "O妹暂不支持表情符号") if (address || "").judge_emoji
    errors.add(:addressee, "O妹暂不支持表情符号") if (addressee || "").judge_emoji
  end

  def unless_delete?
    active == true
  end

  after_create :set_default, if: :is_default
  before_create :get_length
  before_create :set_first_default
  after_update :set_default, if: ->(model) { model.is_default_changed? && model.is_default }
  scope :by_default, ->{where(is_default: true)}

  def set_default
    Core::Address.transaction do
      address = Core::Address.where(user_id: user_id, is_default: true)
      if address.present?
        address.each do |a|
          a.update!(is_default: false)
        end
      end
      self.update_column(:is_default, true)
    end
  end

  def set_first_default
    @addresses = Core::Address.active.where(user_id: user_id)
    self.is_default = true unless @addresses.present?
  end

  def get_length
    return false if Core::Address.active.where(user_id: user_id).size >= 50
  end

end
