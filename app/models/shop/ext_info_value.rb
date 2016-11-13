class Shop::ExtInfoValue < ActiveRecord::Base
  belongs_to :ext_info, class_name: "Shop::ExtInfo", foreign_key: :ext_info_id
  belongs_to :resource, polymorphic: true
end
