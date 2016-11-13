# encoding: utf-8

class ShopTopicUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :qiniu

  def store_dir
    model.nil? ? default_dir : model_dir
  end

  def model_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_dir
    "uploads/shop_events/#{mounted_as}/uploaders"
  end

  def default_url
    ActionController::Base.helpers.asset_path(super)
  end

  version :app_cover do
    process :resize_to_fill => [640, 446]
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    Digest::SHA1.hexdigest(read || "") if original_filename
  end

  private

  def full_filename(for_file)
    if version_name.present? && model.try(:"#{mounted_as}_fingerprint")
      [version_name, model.send(:"#{mounted_as}_fingerprint"), for_file].compact.join('_')
    elsif version_name.present?
      [version_name, model.send(:"#{mounted_as}_identifier")].compact.join('_')
    else
      super
    end
  end

end
