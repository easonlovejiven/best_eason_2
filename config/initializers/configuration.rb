SMS_CONFIG = YAML::load_file("#{Rails.root}/config/sms.yml")[RAILS_ENV]
REDIS_CONFIG = YAML::load_file("#{Rails.root}/config/redis.yml")[RAILS_ENV]
OAUTH_CONFIG = YAML::load_file("#{Rails.root}/config/oauth.yml")
ERROR = YAML::load_file("#{Rails.root}/config/locales/errors.yml")
