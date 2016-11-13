class Core::Finding < ActiveRecord::Base
  mount_uploader :pic, CorePicUploader
  mount_uploader :pic2, CorePicUploader

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  scope :active, -> { where(active: true) }
  scope :published, -> { active.where(published: true) }

  def picture_url
    pic.url.present? ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : nil
  end

  def pic2_url
    pic2.url.present? ? "http://#{Settings.qiniu["host"]}/#{pic2.try(:current_path)}" : nil
  end

  cattr_accessor :manage_fields
  self.manage_fields = %w[title category url count pic pic2 description]

  enum category: {"粉丝会"=>"fans", "机构"=>"org", "明星"=>"star", "任务"=> 'task'}
end
