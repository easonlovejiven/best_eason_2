class Welfare::LetterImage < ActiveRecord::Base
  # mount_uploader :pic, CorePicUploader

  scope :active, -> { where(active: true) }

  # def picture_url
  #   pic.try(:url)
  # end
  def picture_url
    pic.blank? ? nil : pic.include?('#') ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : "http://#{Settings.qiniu["host"]}/#{pic}"
  end
end
