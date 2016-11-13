CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = Rails.application.secrets.qiniu_access_key
  config.qiniu_secret_key    = Rails.application.secrets.qiniu_secret_key
  config.qiniu_bucket        = Rails.application.secrets.qiniu_host_name
  config.qiniu_bucket_domain = Rails.application.secrets.qiniu_host
  config.qiniu_bucket_private= true #default is false
  # config.qiniu_block_size    = 4*1024*1024
  config.qiniu_protocol      = "http"
  config.enable_processing   = true
end

class CarrierStringIO < StringIO
  def original_filename
    # the real name does not matter
    "photo.jpeg"
  end

  def content_type
    # this should reflect real content type, but for this example it's ok
    "image/jpeg"
  end
end
