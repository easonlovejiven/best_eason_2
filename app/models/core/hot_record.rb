class Core::HotRecord < ActiveRecord::Base
  include ActAsActivable

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"
  scope :active, -> { where(active: true) }
  scope :positions, -> { active.order("position desc, created_at desc") }

  cattr_accessor :manage_fields
  self.manage_fields = %w[name synonym position creator_id updater_id published active]
end
