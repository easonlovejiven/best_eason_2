class Shop::TaskStar < ActiveRecord::Base
  belongs_to :shop_task, class_name: "Shop::Task"
  belongs_to :core_star, class_name: "Core::Star"
end
