#运费模板
class Shop::FreightTemplate < ActiveRecord::Base
  include ActAsActivable

  has_many :freights, class_name: "Shop::Freight", dependent: :destroy
  belongs_to :user, polymorphic: true, dependent: :destroy, foreign_key: :user_id

  accepts_nested_attributes_for :freights, allow_destroy: true, reject_if: :all_blank

  scope :by_user, ->(user_id){where(user_id: user_id)}

  validates :name, :uniqueness => true, presence: true
  validates_presence_of :freights, message: "如果创建运费，运费模板信息为必填！"

  cattr_accessor :manage_fields do
    %w[ id name user_id start_position user_type ] << {freights_attributes: %w{ freight_template_id start_position destination frist_item id reforwarding_item first_fee reforwarding_fee id_delivery}}
  end

end
