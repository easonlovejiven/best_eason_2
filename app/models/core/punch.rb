class Core::Punch < ActiveRecord::Base
  scope :active, -> { where(active: true) }
  scope :is_punch, ->(time) { active.where("created_at >= ?", time) }
end
