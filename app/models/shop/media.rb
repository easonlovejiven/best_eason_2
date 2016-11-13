class Shop::Media < ActiveRecord::Base
  include Shop::TaskHelper
  include Redis::Objects
  include ActAsActivable

  counter :participator #参与活动人数
  counter :read_subject_participator

  # mount_uploader :pic, CorePicUploader
  validates :title, length: { maximum: 30, too_long: "最多输入30个文字" }
  validates :description, length: { maximum: 15000, too_long: "最多输入15000个文字" }
  KIND_TYPES = {'url' => '仅外链', 'imagetext' => '图文外链'}

  has_one :shop_task, as: :shop, class_name: "Shop::Task"
  belongs_to :creator, class_name: "Core::User", foreign_key: :creator_id
  belongs_to :updater, class_name: "Core::User", foreign_key: :updater_id
  belongs_to :user, class_name: "Core::User", foreign_key: :user_id

  def picture_url
    pic ? "http://#{Settings.qiniu["host"]}/#{pic}" : nil
  end

  def cover_pic
    "http://#{Settings.qiniu["host"]}/#{pic}"
  end

  cattr_accessor :manage_fields do
    %w[ id title start_at end_at url pic user_id guide is_share updater_id creator_id kind description ] << {star_list: []}
  end

end
