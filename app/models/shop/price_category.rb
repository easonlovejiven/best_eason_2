#价格分类信息
class Shop::PriceCategory < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module

  has_many :ticket_types, class_name: "Shop::TicketType", foreign_key: :category_id

  validates_presence_of :name

  cattr_accessor :manage_fields do
    %w[ id name ]
  end
end
