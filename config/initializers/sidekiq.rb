require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq/web'
require 'sidekiq-cron'
Sidekiq::Grouping::Config.poll_interval = 5     # Amount of time between polling batches
Sidekiq::Grouping::Config.max_batch_size = 5000 # Maximum batch size allowed
Sidekiq::Grouping::Config.lock_ttl = 1          # Batch queue flush lock timeout job enqueues
if Rails.env.development? or Rails.env.test?
  redis_config = {
    :url => "redis://#{REDIS_CONFIG['host']}:#{REDIS_CONFIG['port']}/0"
  }
else
  redis_config = {
    :url => "redis://#{REDIS_CONFIG['host']}:#{REDIS_CONFIG['port']}/0"
  }
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
  config.redis = redis_config
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["sidekiqadmin", "1c3cr34m"]
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
  #定时任务
  schedule_file = "config/locales/schedule.yml"

  if File.exists?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end
