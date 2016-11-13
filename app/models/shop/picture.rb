class Shop::Picture < ActiveRecord::Base
  mount_uploader :cover, ShopPictureUploader

  belongs_to :pictureable, polymorphic: true

  def picture_url
    key.blank? ? (cover.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover.try(:current_path)}" : nil) : cover.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover.try(:current_path)}" : key_url #前端发布后即不可修改
  end

  def key=(val)
    super CGI.escape(CGI.unescape(val.to_s))
  end

  def key_url
    ("http://" + Settings.qiniu["host"] + "/" + key).to_s
  end

  cattr_accessor :manage_fields do
    %w[ id pictureable_id pictureable_type cover key ]
  end

end
