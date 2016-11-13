# encoding: utf-8

class ShopEventUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :qiniu

  #当上传后图片后 在前端页面直接查看的缓存文件
  # def cache_dir
  #   '/tmp/projectname-cache'
  # end
  # # Provide a default URL as a default if there hasn't been a file uploaded:
  # # def default_url
  # #   # For Rails 3.1+ asset pipeline compatibility:
  # #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  # #
  # #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # # end
  #返回固定大小的图片 uploader.thumb.url # => '/url/to/thumb_my_file.png'   # size: 200x200
  # version :small do
  #   process :resize_to_fill => [200, 200]
  # end
  # process resize_to_fit: [200, 200] #设置这个之后就不会再传比这个图片大的

  # # from_version 会使用thumb的缓存图片进行裁切
  # version :small_thumb, from_version: :thumb do
  #   process :resize_to_fill => [50, 50]
  # end

  # 要对是否后台人员进行判断 后续根据权限更新

  def store_dir
    model.nil? ? default_dir : model_dir
  end

  def model_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_dir
    "uploads/shop_events/#{mounted_as}/uploaders"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))

    ActionController::Base.helpers.asset_path(super)
  end

  # Process files as they are uploaded:
  # process :scale => [480, 0]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :app_cover do
    process :resize_to_fill => [640, 446]
  end

  version :poster do
    process :resize_to_fill => [899,351]
  end

  version :cover do
    process :resize_to_fill => [358,185]
  end

  version :wide do
    process :resize_to_fill => [1280,720]
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    # model.send(:"#{mounted_as}_fingerprint=", nil) if model.send(:"#{mounted_as}_changed?")
    Digest::SHA1.hexdigest(read || "") if original_filename
  end

  private
  ##
  # This overrides CarrierWave::Uploader::Versions#full_filename
  # method so that we can add a fingerprint to the filename on read.
  #
  def full_filename(for_file)
    # 兼容 #{mounted_as}_fingerprint
    if version_name.present? && model.try(:"#{mounted_as}_fingerprint")
      [version_name, model.send(:"#{mounted_as}_fingerprint"), for_file].compact.join('_')
    elsif version_name.present?
      [version_name, model.send(:"#{mounted_as}_identifier")].compact.join('_')
    else
      super
    end
  end

end
