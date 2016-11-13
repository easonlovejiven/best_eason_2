class Core::Expen < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module

  belongs_to :resource, polymorphic: true
  belongs_to :task, class_name: "Shop::Task"
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  belongs_to :ticket_type, class_name: "Shop::TicketType", foreign_key: :shop_ticket_type_id
  has_many :ext_info_values, ->{where(active: true)}, as: :resource, dependent: :destroy, class_name: 'Shop::ExtInfoValue'
  belongs_to :core_address, class_name: "Core::Address", foreign_key: :address_id

  after_create :update_participator

  validates :order_no, uniqueness: true, if: "order_no.present?"

  scope :shop, ->{where("resource_type='Welfare::Event' or resource_type='Welfare::Product'")}

  def update_participator
    task = self.tries(:task, :shop)
    task.tries(:participator, :incr) unless task.class == Welfare::Product || task.class == Welfare::Event
  end

end
