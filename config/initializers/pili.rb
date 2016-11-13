require 'pili'
Pili.class_eval do
  def self.credentials
    @credentials ||= Pili::Credentials.new(Rails.application.secrets.pili_access_key, Rails.application.secrets.pili_secret_key)
  end

  def self.hub
    @hub ||= Pili::Hub.new(credentials, "owhat1")
  end
end

# Pili.setup! access_key: Rails.application.secrets.pili_access_key,
            # secret_key: Rails.application.secrets.pili_secret_key

            # {   :rtmp_publish_host  => "pub.z1.glb.pili.qiniup.com",
            #   :rtmp_play_host       => "live.z1.glb.pili.qiniucdn.com",
            #   :hls_play_host          => "hls.z1.glb.pili.qiniuapi.com" }
