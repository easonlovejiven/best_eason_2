require "ohm"

Ohm.redis = Redic.new("redis://#{Rails.application.secrets.redis_host}:6379/1")
