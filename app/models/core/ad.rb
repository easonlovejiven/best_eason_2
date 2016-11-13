class Core::Ad < ActiveRecord::Base
  mount_uploader :pic, CorePicUploader

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  scope :active, -> { where(active: true) }

  scope :published, -> { active.where(published: true) }
  scope :effective, -> { published.where("end_at > ? and start_at < ?", Time.now, Time.now)}

  cattr_accessor :manage_fields
  self.manage_fields = %w[title link pic genre duration start_at end_at]

  def picture_url
    pic.url.present? ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : nil
  end

  enum genre: {"苹果"=>"ios", "安卓"=>"android", "网站"=>"web", '全部'=>'all'}
end
