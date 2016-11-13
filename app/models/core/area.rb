class Core::Area < ActiveRecord::Base
  scope :by_provinces, ->{where(ancestry: nil)}
  scope :by_cities, ->(ancestry){where(ancestry: ancestry)}
end
