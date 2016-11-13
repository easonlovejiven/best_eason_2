class Welfare::Paper < ActiveRecord::Base
  mount_uploader :pic, CorePicUploader

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  scope :active, -> { where(active: true) }
  scope :published, -> { active.where(published: true) }

  def picture_url
    key.present? ?
    "http://#{Settings.qiniu["host"]}/#{key}" :
    (pic.url.present? ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : nil)
  end

  cattr_accessor :manage_fields
  self.manage_fields = %w[key]
end
