Rongcloud.setup do
  self.app_key    = Rails.application.secrets.rongcloud.try(:[], "app_key")
  self.app_secret = Rails.application.secrets.rongcloud.try(:[], "app_secret")
end