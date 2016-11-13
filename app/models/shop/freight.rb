#运费
class Shop::Freight < ActiveRecord::Base
  include ActAsActivable
  
  belongs_to :freight_template, class_name: "Shop::FreightTemplate", foreign_key: :freight_template_id
  validates :destination, presence: true
end
